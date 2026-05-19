import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  bool _enabled = kIsWeb; // default on for Flutter Web (Telebirr has no console)
  bool _collapsed = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPref();
  }

  Future<void> _loadPref() async {
    bool forceEnable = false;
    if (kIsWeb) {
      // `?superappDebug=1` forces the panel on (useful after disabling it).
      forceEnable = Uri.base.queryParameters['superappDebug'] == '1';
    }

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_prefKey);
    final next = forceEnable ? true : (stored ?? (kIsWeb ? true : false));

    if (!mounted) return;
    setState(() => _enabled = next);

    if (forceEnable) {
      await prefs.setBool(_prefKey, true);
      AppLogger.setEnabled(true);
      AppLogger.log('Debug panel force-enabled via ?superappDebug=1');
    }
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
    if (!_enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 12,
          left: 12,
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
    final match = RegExp(r'^\[[0-9]{2}:[0-9]{2}:[0-9]{2}\]\[([A-Z]+)\]')
        .firstMatch(line);
    return match?.group(1) ?? 'INFO';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = math.min(460.0, math.max(260.0, screenWidth - 24));

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.78),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ValueListenableBuilder<List<String>>(
            valueListenable: AppLogger.lines,
            builder: (context, lines, _) {
              final text = lines.isEmpty ? '(no logs yet)' : lines.join('\n');

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!scrollController.hasClients) return;
                scrollController.jumpTo(scrollController.position.maxScrollExtent);
              });

              final lastLine = lines.isEmpty ? '(no logs yet)' : lines.last;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'SuperApp Debug',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onToggleCollapsed,
                        child: Text(
                          collapsed ? 'Expand' : 'Collapse',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: onClear,
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () => onCopy(context, text),
                        child: const Text(
                          'Copy',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: onDisable,
                        child: const Text(
                          'Disable',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  if (collapsed) ...[
                    const SizedBox(height: 8),
                    Text(
                      lastLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _colorForLine(lastLine, context),
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: Scrollbar(
                        controller: scrollController,
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: lines.length,
                          itemBuilder: (context, index) {
                            final line = lines[index];
                            return Text(
                              line,
                              style: TextStyle(
                                color: _colorForLine(line, context),
                                fontFamily: 'monospace',
                                fontSize: 12,
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
    );
  }
}
