import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/core/cbebirr_plus/cbebirr_plus_bridge.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';

class CbeBirrPage extends StatefulWidget {
  const CbeBirrPage({super.key});

  @override
  State<CbeBirrPage> createState() => _CbeBirrPageState();
}

class _CbeBirrPageState extends State<CbeBirrPage> {
  String? _token;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadToken());
  }

  void _loadToken() {
    final bridge = createCbeBirrPlusBridge();
    final raw = bridge.launchToken;
    final token = (raw != null && raw.trim().isNotEmpty) ? raw.trim() : null;

    if (token != null) {
      AppLogger.success('CBEBirr: token received (len=${token.length})');
      DataController().storeData('cbeBirrToken', token);
    } else {
      AppLogger.warn('CBEBirr: no token received');
    }

    if (mounted) {
      setState(() {
        _token = token;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('CBE Birr Plus'),
        backgroundColor: AppColors.deepForestGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420.w),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 32.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CbeBirrLogo(),
                  SizedBox(height: 18.h),
                  Text(
                    'CBE Birr Plus',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepForestGreen,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Authorization token from CBE Birr Plus',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.sp, color: Colors.black54),
                  ),
                  SizedBox(height: 28.h),
                  if (!_loaded)
                    SizedBox(
                      height: 40.h,
                      width: 40.h,
                      child: const CircularProgressIndicator(
                        color: AppColors.deepForestGreen,
                        strokeWidth: 2.5,
                      ),
                    )
                  else if (_token != null)
                    _TokenPanel(token: _token!)
                  else
                    const _NoTokenPanel(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CbeBirrLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.w,
      height: 100.w,
      decoration: BoxDecoration(
        color: AppColors.deepForestGreen.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.account_balance_wallet_rounded,
        size: 54.sp,
        color: AppColors.deepForestGreen,
      ),
    );
  }
}

class _TokenPanel extends StatelessWidget {
  const _TokenPanel({required this.token});

  final String token;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.deepForestGreen.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(8.r),
        color: AppColors.deepForestGreen.withOpacity(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 18.sp, color: Colors.green.shade600),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'Token received',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _copy(context),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded,
                          size: 16.sp, color: AppColors.deepForestGreen),
                      SizedBox(width: 4.w),
                      Text(
                        'Copy',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.deepForestGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          SelectableText(
            token,
            style: TextStyle(
              fontSize: 12.sp,
              fontFamily: 'monospace',
              color: AppColors.deepForestGreen,
              height: 1.35,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${token.length} chars · saved',
            style: TextStyle(fontSize: 10.sp, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}

class _NoTokenPanel extends StatelessWidget {
  const _NoTokenPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Icon(Icons.token_outlined, size: 36.sp, color: Colors.orange.shade600),
          SizedBox(height: 10.h),
          Text(
            'No token received from CBE Birr Plus',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade800,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'The token is sent via the Authorization header when CBE Birr Plus opens this page.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.orange.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
