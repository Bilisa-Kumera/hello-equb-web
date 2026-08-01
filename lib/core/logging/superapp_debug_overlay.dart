import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helloequb/core/env_config.dart';
import 'package:helloequb/core/cbebirr_plus/cbebirr_plus_bridge.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:helloequb/features/superapp_auth/config/superapp_auth_config.dart';
import 'package:helloequb/utils/style_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'telebirr_superapp_detector.dart';

class SuperAppDebugOverlay extends StatefulWidget {
  const SuperAppDebugOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<SuperAppDebugOverlay> createState() => _SuperAppDebugOverlayState();
}

class _SuperAppDebugOverlayState extends State<SuperAppDebugOverlay> {
  static const _prefKey = 'superapp_debug_panel_enabled';

  bool _enabled = _debugEnabledFromEnv();
  bool _collapsed = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPref().then((_) {
      if (!mounted) return;
      _checkSuperAppEnvironment();
    });
  }

  Future<void> _checkSuperAppEnvironment() async {
    final cbeBridge = createCbeBirrPlusBridge();
    if (cbeBridge.isAvailable) return;

    final cbeOk = await cbeBridge.waitUntilAvailable(
      timeout: const Duration(seconds: 2),
      pollInterval: const Duration(milliseconds: 140),
    );
    if (cbeOk) return;

    await checkTelebirrSuperApp();
  }

  Future<void> checkTelebirrSuperApp() async {
    final merchantId = SuperAppAuthConfig.fromEnv().merchantAppId;
    if (merchantId.isEmpty) {
      AppLogger.error(
        'Telebirr merchant ID is missing. Set MERCHANT_APP_ID via --dart-define.',
      );
      return;
    }

    AppLogger.log('Checking Telebirr ConsumerApp bridge');
    final result = await TelebirrSuperAppDetector.detect(
      merchantId: merchantId,
    );

    AppLogger.log('Telebirr Detect Result: $result');

    if (result.hasTelebirrBridge) {
      AppLogger.success(
        'Telebirr detect final | result=bridge_found | stage=${result.stage ?? 'unknown'} | location=${result.location ?? 'unknown'}',
      );
    } else {
      AppLogger.warn(
        'Telebirr detect final | result=bridge_not_found | stage=${result.stage ?? 'unknown'} | location=${result.location ?? 'unknown'} | reason=${result.error ?? result.message ?? 'bridge requirements not met'}',
      );
    }

    if (result.error != null) {
      AppLogger.error(
        'Telebirr detect error detail | stage=${result.stage ?? 'unknown'} | location=${result.location ?? 'unknown'} | result=${result.result ?? 'failure'} | error=${result.error}',
      );
    }
  }

  Future<void> _loadPref() async {
    bool forceEnable = false;
    if (kIsWeb) {
      // `?superappDebug=1` forces the panel on (useful after disabling it).
      forceEnable = Uri.base.queryParameters['superappDebug'] == '1';
    }

    final envOverride = _debugEnvOverride();
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_prefKey);
    final next = forceEnable ? true : (envOverride ?? stored ?? kIsWeb);

    if (!mounted) return;
    setState(() => _enabled = next);

    AppLogger.setEnabled(next);

    if (forceEnable) {
      await prefs.setBool(_prefKey, true);
      AppLogger.setEnabled(true);
      AppLogger.log('Debug panel force-enabled via ?superappDebug=1');
    }
  }

  static bool _debugEnabledFromEnv() {
    return _debugEnvOverride() ?? kIsWeb;
  }

  static bool? _debugEnvOverride() {
    final value = EnvConfig.superappDebug.trim();
    if (value.isEmpty) return null;
    return _isTruthy(value);
  }

  static bool _isTruthy(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'on';
  }

  Future<void> _setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
    AppLogger.setEnabled(enabled);
    if (!mounted) return;
    setState(() => _enabled = enabled);
  }

  void _clearLogs() {
    AppLogger.clear();
    AppLogger.log('logs cleared');
  }

  Future<void> _copyLogs(BuildContext context, String text) async {
    final data = ClipboardData(text: text);
    await Clipboard.setData(data);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied')),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _Panel(
              collapsed: _collapsed,
              onToggleCollapsed: () {
                setState(() => _collapsed = !_collapsed);
              },
              onDisable: () => _setEnabled(false),
              onClear: _clearLogs,
              onCopy: _copyLogs,
              scrollController: _scrollController,
            ),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.onDisable,
    required this.onClear,
    required this.onCopy,
    required this.scrollController,
  });

  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onDisable;
  final VoidCallback onClear;
  final Future<void> Function(BuildContext context, String text) onCopy;
  final ScrollController scrollController;

  Color _colorForLine(String line, BuildContext context) {
    final level = _extractLevel(line);
    switch (level) {
      case 'ERROR':
        return Colors.red.shade300;
      case 'WARN':
        return Colors.amber.shade300;
      case 'SUCCESS':
        return Colors.green.shade300;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  String _extractLevel(String line) {
    final match =
        RegExp(r'^\[[0-9]{2}:[0-9]{2}:[0-9]{2}\]\[([A-Z]+)\]').firstMatch(line);
    return match?.group(1) ?? 'INFO';
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final width = math.min(720.0, math.max(280.0, screenWidth - 16));
    final maxHeight = math.max(160.0, media.size.height * 0.38);

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.88),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ValueListenableBuilder<List<String>>(
              valueListenable: AppLogger.lines,
              builder: (context, lines, _) {
                final text = lines.isEmpty ? '(no logs yet)' : lines.join('\n');

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!scrollController.hasClients) return;
                  scrollController
                      .jumpTo(scrollController.position.maxScrollExtent);
                });

                final lastLine = lines.isEmpty ? '(no logs yet)' : lines.last;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'SuperApp Console',
                            style: AppTextStyles.poppins70014
                                .copyWith(color: Colors.white),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: collapsed ? 'Expand' : 'Collapse',
                          child: IconButton(
                            onPressed: onToggleCollapsed,
                            icon: Icon(
                              collapsed
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Clear',
                          child: IconButton(
                            onPressed: onClear,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Copy',
                          child: IconButton(
                            onPressed: () => onCopy(context, text),
                            icon: const Icon(
                              Icons.copy,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Hide console',
                          child: IconButton(
                            onPressed: onDisable,
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (collapsed) ...[
                      const SizedBox(height: 4),
                      Text(
                        lastLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: _colorForLine(lastLine, context),
                          fontFamily: 'monospace',
                          height: 1.25,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxHeight),
                        child: Scrollbar(
                          controller: scrollController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: lines.length,
                            itemBuilder: (context, index) {
                              final line = lines[index];
                              return SelectableText(
                                line,
                                style: AppTextStyles.caption.copyWith(
                                  color: _colorForLine(line, context),
                                  fontFamily: 'monospace',
                                  height: 1.25,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
