// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:helloequb/screens/my_other_ekubs.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/models/ekub_category_model.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:confetti/confetti.dart';

import '../utils/secure_storage.dart';

class FortuneWheelScreen extends StatefulWidget {
  final int round;
  final String ekubId;
  String? ekubAmount;
  final String ekubName;
  final int ekubersNumber, ekubCycle;
  final String nextRoundDate;
  final String nextRoundTime;
  final bool ekubRequest;
  final String nextRoundLotteryType;
  final String serviceCharge;
  final List<dynamic> elligibleMembersSocket;
  final List<dynamic> currentRoundWinnersSocket;
  final List<dynamic> equbElligibleMembersSocket;

  FortuneWheelScreen({
    super.key,
    required this.round,
    required this.ekubId,
    this.ekubAmount,
    required this.ekubName,
    required this.ekubersNumber,
    required this.ekubCycle,
    required this.nextRoundDate,
    required this.nextRoundTime,
    required this.ekubRequest,
    required this.nextRoundLotteryType,
    required this.serviceCharge,
    required this.elligibleMembersSocket,
    required this.currentRoundWinnersSocket,
    required this.equbElligibleMembersSocket,
  });

  @override
  State<FortuneWheelScreen> createState() => _SpinWheelState();
}

class _SpinWheelState extends State<FortuneWheelScreen>
    with SingleTickerProviderStateMixin {
  final confettiController =
      ConfettiController(duration: const Duration(seconds: 2));

  Timer? _countdownTimer;
  int countdown = 10;

  late AnimationController _animController;
  late Animation<double> _rotationAnimation;

  double _currentAngle = 0.0;
  bool _isSpinning = false;
  int winnerIndex = 0;
  int currentWinnerIndex = 0;
  int round = 1;

  List<String> shuffledItems = [];
  List<String> elligibleUsersLotteryList = [];
  List<String> winnersList = [];

  final Dio dio = Dio();
  final DataController dataController = DataController();
  bool _isLoading = true;

  // Slice colors – alternating so adjacent slices are always distinguishable
  static const Color _colorA = Color(0xFF1B5E20);
  static const Color _colorB = Color(0xFF388E3C);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.elligibleMembersSocket.isNotEmpty &&
          widget.currentRoundWinnersSocket.isNotEmpty) {
        _setEligibleDataFromSocket();
      } else {
        _getElligbleUsers();
      }
    });
  }

  // ─── Data loading ──────────────────────────────────────────────────────────

  void _setEligibleDataFromSocket() {
    elligibleUsersLotteryList.clear();
    winnersList.clear();

    elligibleUsersLotteryList
        .addAll(widget.elligibleMembersSocket.map((e) => e['lotteryNumber']));
    winnersList.addAll(
        widget.currentRoundWinnersSocket.map((e) => e['lotteryNumber']));

    if (widget.currentRoundWinnersSocket.isNotEmpty) {
      round = widget.currentRoundWinnersSocket.first['winRound'];
    }

    _handleLoadedData();
  }

  Future<void> _getElligbleUsers({bool fromCountdown = false}) async {
    final bearerToken = await SecureStorageHelper.getAccessToken() ?? '';
    try {
      final response = await dio.get(
        getEligibleUsers + widget.ekubId,
        options: Options(headers: {"Authorization": "Bearer $bearerToken"}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final eligibleMembers = data['eligibleMembers'] as List<dynamic>;
        final currentWinners = data['currentRoundWinners'] as List<dynamic>;

        elligibleUsersLotteryList.clear();
        winnersList.clear();

        elligibleUsersLotteryList.addAll(
            eligibleMembers.map((e) => e['lotteryNumber']).cast<String>());
        winnersList.addAll(
            currentWinners.map((e) => e['lotteryNumber']).cast<String>());

        if (currentWinners.isNotEmpty) {
          round = currentWinners.first['winRound'];
        }

        if (fromCountdown) {
          // Refresh wheel data without restarting the countdown timer.
          _shuffleItems();
          if (mounted) setState(() {});
        } else {
          _handleLoadedData();
        }
      } else {
        _showErrorDialog('Failed to retrieve data. Please try again.');
      }
    } catch (_) {
      _showErrorDialog(
          'Seems like there are no eligible Equbers or no winners for this round.');
    }
  }

  void _handleLoadedData() {
    if (elligibleUsersLotteryList.isEmpty && winnersList.isEmpty) {
      _showErrorDialog('No eligible users or winners found.');
      return;
    }
    if (elligibleUsersLotteryList.isEmpty && winnersList.length == 1) {
      setState(() => _isLoading = false);
      _showWinnerDialog(winnersList[0]);
      return;
    }
    _shuffleItems();
    setState(() => _isLoading = false);
    _startCountdown();
  }

  // ─── Wheel logic ───────────────────────────────────────────────────────────

  void _shuffleItems() {
    shuffledItems = elligibleUsersLotteryList.toSet().toList()..shuffle();
    for (final w in winnersList) {
      if (!shuffledItems.contains(w)) shuffledItems.add(w);
    }
    if (winnersList.isEmpty || currentWinnerIndex >= winnersList.length) {
      winnerIndex = 0;
      return;
    }
    winnerIndex = shuffledItems.indexOf(winnersList[currentWinnerIndex]);
    if (winnerIndex < 0) winnerIndex = 0;
  }

  void _startCountdown() {
    countdown = 10;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => countdown--);
      if (countdown <= 0) {
        timer.cancel();
        _startSpinning();
      }
      if (countdown == 5 &&
          widget.elligibleMembersSocket.isEmpty &&
          widget.currentRoundWinnersSocket.isEmpty) {
        _getElligbleUsers(fromCountdown: true);
      }
    });
  }

  void _startSpinning() {
    if (_isSpinning || shuffledItems.isEmpty) return;
    _isSpinning = true;
    _countdownTimer?.cancel();
    final n = shuffledItems.length;
    final sliceAngle = (2 * pi) / n;

    // We want the winning slice to end up under the top indicator (angle = 0).
    // Each slice i occupies [i*sliceAngle, (i+1)*sliceAngle].
    // We spin a minimum of 5 full rotations + offset to land winner at top.
    final winnerMidAngle = winnerIndex * sliceAngle + sliceAngle / 2;
    final desiredFinalAngle = (2 * pi - winnerMidAngle) % (2 * pi);
    final currentMod = _currentAngle % (2 * pi);
    final deltaToWinner =
        (desiredFinalAngle - currentMod + 2 * pi) % (2 * pi);
    final targetAngle = 5 * 2 * pi + deltaToWinner;

    _rotationAnimation = Tween<double>(
      begin: _currentAngle,
      end: _currentAngle + targetAngle,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.decelerate,
    ));

    _animController.forward(from: 0).then((_) {
      // Snap to the exact final value to avoid any perceived post-stop drift.
      _animController.stop(canceled: false);
      _currentAngle = _rotationAnimation.value % (2 * pi);
      final String winnerLabel =
          shuffledItems[winnerIndex % shuffledItems.length];
      confettiController.play();
      _showWinnerDialog(winnerLabel);
      _isSpinning = false;
    });

    setState(() {});
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          textScaleFactor: 1.0,
          "We're Sorry!",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.redAccent),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.redAccent, size: 50),
          const SizedBox(height: 20),
          Text(textScaleFactor: 1.0, message,
              style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(textScaleFactor: 1.0, "OK"),
          ),
        ],
      ),
    );
  }

  void _showWinnerDialog(String winnerLabel) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(
          textScaleFactor: 1.0,
          'Winner Announcement',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.celebration, size: 50, color: AppColors.orange),
          const SizedBox(height: 16),
          Text(textScaleFactor: 1.0, 'The winner is $winnerLabel!',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text(textScaleFactor: 1.0, 'Round: $round',
              style: const TextStyle(fontSize: 16)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: ctx,
                builder: (_) => AlertDialog(
                  title: Text(
                      textScaleFactor: 1.0, AppKeys.information.tr(context)),
                  content: Text(
                      textScaleFactor: 1.0, AppKeys.youCanClaim.tr(context)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                          textScaleFactor: 1.0, AppKeys.ok.tr(context)),
                    ),
                  ],
                ),
              );
            },
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              currentWinnerIndex++;
              if (currentWinnerIndex < winnersList.length) {
                _animController.reset();
                _shuffleItems();
                _startCountdown();
                setState(() {});
              } else {
                await loadEkubCategories();
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ActiveEqubsScreen()),
                  );
                }
              }
            },
            style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(AppColors.primary)),
            child: Text(
              textScaleFactor: 1.0,
              winnersList.length > 1 && currentWinnerIndex < winnersList.length - 1
                  ? 'Next Winner'
                  : 'My Equbs',
              style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.white,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<EqubCategorys>?> loadEkubCategories() async {
    final jsonList = dataController.retrieveData<List<dynamic>>('ekubCategories');
    if (jsonList != null) {
      return jsonList
          .map((j) => EqubCategorys.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  // ─── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animController.dispose();
    confettiController.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width - 32;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isLoading)
                const SpinKitFadingCircle(color: AppColors.primary, size: 50)
              else
                Text(
                  textScaleFactor: 1.0,
                  countdown > 0 ? '$countdown' : 'Spinning...',
                  style: TextStyle(
                      fontSize: 28.sp, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 20),
              if (!_isLoading && shuffledItems.isNotEmpty)
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // ── The custom painted wheel ──
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (_, __) {
                        final angle = _animController.isAnimating
                            ? _rotationAnimation.value
                            : _currentAngle;
                        return CustomPaint(
                          size: Size(size, size),
                          painter: _WheelPainter(
                            items: shuffledItems,
                            rotationAngle: angle,
                            colorA: _colorA,
                            colorB: _colorB,
                          ),
                        );
                      },
                    ),
                    // ── Top indicator triangle ──
                    CustomPaint(
                      size: Size(size, size),
                      painter: const _IndicatorPainter(
                          indicatorColor: AppColors.primary),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
            ],
          ),
          // ── Confetti ──
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirection: -pi / 2,
              maxBlastForce: 30,
              minBlastForce: 18,
              emissionFrequency: 0.05,
              numberOfParticles: 3,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Custom Painter – draws the full wheel with text near the outer rim
// ═══════════════════════════════════════════════════════════════════════════════

class _WheelPainter extends CustomPainter {
  final List<String> items;
  final double rotationAngle;
  final Color colorA;
  final Color colorB;

  const _WheelPainter({
    required this.items,
    required this.rotationAngle,
    required this.colorA,
    required this.colorB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = cx; // wheel fills the full SizedBox
    final n = items.length;
    final sliceAngle = (2 * pi) / n;

    // The indicator points at -pi/2 (top). We rotate so the first slice
    // starts there, then add the animation rotation on top.
    final startOffset = -pi / 2 + rotationAngle;

    final slicePaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 1.5;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    for (int i = 0; i < n; i++) {
      final startAngle = startOffset + i * sliceAngle;

      // ── Fill slice ──
      slicePaint.color = i % 2 == 0 ? colorA : colorB;
      canvas.drawArc(rect, startAngle, sliceAngle, true, slicePaint);

      // ── Slice border ──
      canvas.drawArc(rect, startAngle, sliceAngle, true, borderPaint);

      // ── Label near the outer edge ──
      _drawLabel(
        canvas: canvas,
        label: items[i],
        cx: cx,
        cy: cy,
        radius: radius,
        midAngle: startAngle + sliceAngle / 2,
        sliceAngle: sliceAngle,
        n: n,
      );
    }

    // ── Centre circle (white dot) to hide the pointy centre ──
    canvas.drawCircle(
      Offset(cx, cy),
      radius * 0.08,
      Paint()..color = Colors.white,
    );
  }

  void _drawLabel({
    required Canvas canvas,
    required String label,
    required double cx,
    required double cy,
    required double radius,
    required double midAngle,
    required double sliceAngle,
    required int n,
  }) {
    // Place text at 82 % of the radius from the centre so it sits near the rim.
    const double textRadiusFactor = 0.78;
    final textRadius = radius * textRadiusFactor;

    final tx = cx + textRadius * cos(midAngle);
    final ty = cy + textRadius * sin(midAngle);

    // Font size: fixed floor of 10, shrinks slightly for very many items
    // but never below 7 logical pixels so numbers stay legible.
    final fontSize = (n <= 30 ? 12.0 : n <= 60 ? 10.0 : n <= 100 ? 8.5 : 7.0);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: textRadius * sliceAngle * 0.9); // constrain to arc width

    // Rotate the canvas so the text reads radially outward (like a clock dial).
    canvas.save();
    canvas.translate(tx, ty);
    canvas.rotate(midAngle + pi / 2); // +90° so text base points outward
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.rotationAngle != rotationAngle || old.items != items;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Indicator Painter – draws the triangle pointer at the top
// ═══════════════════════════════════════════════════════════════════════════════

class _IndicatorPainter extends CustomPainter {
  final Color indicatorColor;
  const _IndicatorPainter({required this.indicatorColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final triangleH = size.width * 0.06;
    final triangleW = size.width * 0.04;

    final path = Path()
      ..moveTo(cx, 0) // tip – sits exactly on the rim
      ..lineTo(cx - triangleW, -triangleH)
      ..lineTo(cx + triangleW, -triangleH)
      ..close();

    canvas.drawPath(path, Paint()..color = indicatorColor);
  }

  @override
  bool shouldRepaint(_IndicatorPainter old) =>
      old.indicatorColor != indicatorColor;
}
