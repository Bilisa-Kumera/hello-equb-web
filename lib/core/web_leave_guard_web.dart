// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:helloequb/utils/colors_constant.dart';

const _leaveMessage = 'Are you sure you want to leave the app?';

StreamSubscription<html.Event>? _beforeUnloadSubscription;

void initWebLeaveGuard() {
  _beforeUnloadSubscription ??=
      html.window.onBeforeUnload.listen((html.Event event) {
    final beforeUnloadEvent = event as html.BeforeUnloadEvent;
    beforeUnloadEvent.returnValue = _leaveMessage;
  });
}

class WebLeaveGuard extends StatefulWidget {
  const WebLeaveGuard({super.key, required this.child});

  final Widget child;

  @override
  State<WebLeaveGuard> createState() => _WebLeaveGuardState();
}

class _WebLeaveGuardState extends State<WebLeaveGuard> {
  bool _allowPop = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _allowPop) return;

        final shouldLeave = await _showLeaveDialog(context);
        if (!mounted || !shouldLeave) return;

        setState(() => _allowPop = true);
        Navigator.of(context).maybePop();
        Future<void>.delayed(Duration.zero, () {
          if (mounted) setState(() => _allowPop = false);
        });
      },
      child: widget.child,
    );
  }

  Future<bool> _showLeaveDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          elevation: 18,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 6),
          contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Leave Hello Equb?',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            _leaveMessage,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
