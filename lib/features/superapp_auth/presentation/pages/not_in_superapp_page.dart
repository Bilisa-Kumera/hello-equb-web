import 'package:flutter/material.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/core/superapp/superapp_diagnostics.dart';
import 'package:helloequb/features/superapp_auth/presentation/widgets/superapp_log_panel.dart';

class NotInSuperAppPage extends StatefulWidget {
  const NotInSuperAppPage({super.key});

  @override
  State<NotInSuperAppPage> createState() => _NotInSuperAppPageState();
}

class _NotInSuperAppPageState extends State<NotInSuperAppPage> {
  late final Map<String, String> _diag;

  @override
  void initState() {
    super.initState();
    _diag = createSuperAppDiagnostics().snapshot();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.open_in_browser,
                  size: 84,
                  color: AppColors.deepForestGreen,
                ),
                const SizedBox(height: 16),
                Text(
                  'You are not in the SuperApp',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepForestGreen,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'To use Hello Equb on the web, please open it inside Telebirr SuperApp or CBEBirr Plus.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Detection status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepForestGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFF7F7F7),
                  ),
                  child: SelectableText(
                    _diag.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const SuperAppLogPanel(title: 'Auth / Network logs'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
