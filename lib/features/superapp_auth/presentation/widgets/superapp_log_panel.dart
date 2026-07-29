import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:helloequb/utils/style_constants.dart';

class SuperAppLogPanel extends StatelessWidget {
  const SuperAppLogPanel({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: AppLogger.lines,
      builder: (context, lines, _) {
        final text = lines.isEmpty ? '(no logs yet)' : lines.join('\n');

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFF7F7F7),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title ?? 'Logs',
                      style: AppTextStyles.poppins70014,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logs copied')),
                      );
                    },
                    child: const Text('Copy'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: SingleChildScrollView(
                  child: SelectableText(
                    text,
                    style: AppTextStyles.caption
                        .copyWith(fontFamily: 'monospace', height: 1.25),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
