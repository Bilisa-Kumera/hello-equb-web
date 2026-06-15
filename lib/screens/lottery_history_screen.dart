// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/screens/my_ekub_detail_screen.dart';
import 'package:helloequb/utils/claim_winning_dialog.dart';
import 'package:helloequb/utils/secure_storage.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/screens/guarantor_screen.dart';
import 'package:helloequb/screens/complete_profile_screen.dart';
import 'package:helloequb/models/financial_info.dart';
import '../core/api_service_elper.dart';
import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LotteryWheel
//  Drop-in replacement for the raw CustomPaint call in _buildLotteriesTab.
//  Owns the AnimationController, winner popup, and confetti.
// ─────────────────────────────────────────────────────────────────────────────
class LotteryWheel extends StatefulWidget {
  final List<int> lotteryNumbers;
  final bool isTimeUp;
  final int? winnerLotteryNumber;
  final bool hasNextWinner;

  /// Called after the winner popup is dismissed so the parent can push
  /// the next winner from the queue (multi-winner support).
  final VoidCallback? onSpinComplete;

  const LotteryWheel({
    super.key,
    required this.lotteryNumbers,
    this.isTimeUp = false,
    this.winnerLotteryNumber,
    this.hasNextWinner = false,
    this.onSpinComplete,
  });

  @override
  State<LotteryWheel> createState() => _LotteryWheelState();
}

class _LotteryWheelState extends State<LotteryWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  double _currentAngle = 0.0;
  bool _hasSpun = false;
  bool _showPopup = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..addStatusListener(_onStatus);
    _anim = _ctrl; // will be replaced in _startSpin
  }

  @override
  void didUpdateWidget(covariant LotteryWheel old) {
    super.didUpdateWidget(old);

    // A new winner was pushed in — reset so it gets its own fresh spin.
    if (old.winnerLotteryNumber != widget.winnerLotteryNumber) {
      _hasSpun = false;
      _showPopup = false;
      _ctrl.reset();
      _currentAngle = 0;
    }

    _maybeStartSpin();
  }

  void _maybeStartSpin() {
    if (widget.isTimeUp &&
        widget.winnerLotteryNumber != null &&
        !_hasSpun &&
        !_ctrl.isAnimating) {
      _startSpin();
    }
  }

  // ── Compute the exact rotation that lands the winner under the pointer ──
  double _targetAngle(int winner) {
    final count = widget.lotteryNumbers.length;
    if (count == 0) return 0;
    final idx = widget.lotteryNumbers.indexOf(winner);
    final effectiveIdx = idx < 0 ? 0 : idx;
    final seg = 2 * pi / count;
    final segMid = effectiveIdx * seg - pi / 2 + seg / 2;
    // pointer is at −π/2; rotate so segMid lands there
    double rot = -pi / 2 - segMid;
    rot = ((rot % (2 * pi)) + 2 * pi) % (2 * pi);
    return rot;
  }

  void _startSpin() {
    _hasSpun = true;

    final target = _targetAngle(widget.winnerLotteryNumber!);
    final current = _currentAngle % (2 * pi);
    double delta = target - current;
    if (delta < 0) delta += 2 * pi;

    // 8 full rotations + precise landing angle
    final endAngle = _currentAngle + (8 * 2 * pi) + delta;

    _anim = _ctrl.drive(
      Tween<double>(begin: _currentAngle, end: endAngle).chain(
        CurveTween(curve: Curves.decelerate),
      ),
    );

    _ctrl.forward(from: 0);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _currentAngle = _anim.value;
      setState(() => _showPopup = true);
    }
  }

  void _closePopup() {
    setState(() => _showPopup = false);
    widget.onSpinComplete?.call();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wheelSize = MediaQuery.of(context).size.width - 48.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Wheel canvas ──
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            if (_ctrl.isAnimating) _currentAngle = _anim.value;
            return CustomPaint(
              size: Size(wheelSize, wheelSize),
              painter: AnimatedWheelPainter(
                lotteryNumbers: widget.lotteryNumbers,
                angle: _currentAngle,
                isTimeUp: widget.isTimeUp,
                winnerLotteryNumber: widget.winnerLotteryNumber,
              ),
            );
          },
        ),

        // ── Winner popup ──
        if (_showPopup)
          Positioned.fill(
            child: _WinnerPopup(
              winnerNumber: widget.winnerLotteryNumber!,
              hasNextWinner: widget.hasNextWinner,
              onClose: _closePopup,
            ),
          ),

        // ── Confetti ──
        if (_showPopup)
          Positioned.fill(
            child: IgnorePointer(
              child: _ConfettiLayer(
                key: ValueKey('confetti_${widget.winnerLotteryNumber}'),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AnimatedWheelPainter  — pure CustomPainter, no state
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedWheelPainter extends CustomPainter {
  final List<int> lotteryNumbers;
  final double angle;
  final bool isTimeUp;
  final int? winnerLotteryNumber;

  const AnimatedWheelPainter({
    required this.lotteryNumbers,
    this.angle = 0,
    this.isTimeUp = false,
    this.winnerLotteryNumber,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final segmentCount = lotteryNumbers.length;
    if (segmentCount == 0) return;

    // Wheel stays still until isTimeUp AND winnerLotteryNumber is set.
    final effectiveAngle =
        (isTimeUp && winnerLotteryNumber != null) ? angle : 0.0;

    final seg = 2 * pi / segmentCount;

    final greenPaint = Paint()..color = const Color.fromARGB(255, 8, 162, 246);
    final whitePaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // ── Rotate wheel ──
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(effectiveAngle);
    canvas.translate(-cx, -cy);

    for (int i = 0; i < segmentCount; i++) {
      final start = i * seg - pi / 2;

      final path = Path()
        ..moveTo(cx, cy)
        ..arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: r),
          start,
          seg,
          false,
        )
        ..close();

      canvas.drawPath(path, i % 2 == 0 ? greenPaint : whitePaint);
      canvas.drawPath(path, borderPaint);

      final mid = start + seg / 2;
      final tx = cx + (r - 14) * cos(mid);
      final ty = cy + (r - 14) * sin(mid);

      final tp = TextPainter(
        text: TextSpan(
          text: '${lotteryNumbers[i]}',
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            color: i % 2 == 0 ? Colors.white : Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(mid + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    canvas.restore();

    // ── Center circle ──
    canvas.drawCircle(
      Offset(cx, cy),
      40,
      Paint()..color = const Color.fromARGB(255, 10, 159, 245),
    );

    // ── Pointer (always fixed at top) ──
    final arrowPath = Path()
      ..moveTo(cx - 14, cy - 22)
      ..lineTo(cx, cy - 58)
      ..lineTo(cx + 14, cy - 22)
      ..close();
    canvas.drawPath(
        arrowPath, Paint()..color = const Color.fromARGB(255, 254, 214, 13));
  }

  @override
  bool shouldRepaint(covariant AnimatedWheelPainter old) =>
      old.angle != angle ||
      old.lotteryNumbers != lotteryNumbers ||
      old.isTimeUp != isTimeUp ||
      old.winnerLotteryNumber != winnerLotteryNumber;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Winner popup
// ─────────────────────────────────────────────────────────────────────────────
class _WinnerPopup extends StatelessWidget {
  final int winnerNumber;
  final bool hasNextWinner;
  final VoidCallback onClose;
  const _WinnerPopup({
    required this.winnerNumber,
    required this.hasNextWinner,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 8),
              const Text(
                'We have a winner!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'The lucky lottery number is',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$winnerNumber',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                  fontFamily: 'Poppins',
                  height: 1,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                onPressed: onClose,
                child: Text(
                  hasNextWinner ? 'Next' : 'Close',
                  style: const TextStyle(fontSize: 15, fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Confetti layer
// ─────────────────────────────────────────────────────────────────────────────
class _ConfettiLayer extends StatefulWidget {
  const _ConfettiLayer({super.key});

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;
  final _rng = Random();

  static const _colors = [
    Color(0xFF4CAF50),
    Color(0xFFE53935),
    Color(0xFF1565C0),
    Color(0xFFF9A825),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFFFF7043),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )
      ..addListener(() => setState(() {}))
      ..forward();

    _particles = List.generate(
        160,
        (_) => _Particle(
              x: _rng.nextDouble(),
              y: -0.05 - _rng.nextDouble() * 0.4,
              vx: (_rng.nextDouble() - 0.5) * 0.008,
              vy: 0.004 + _rng.nextDouble() * 0.008,
              w: 6 + _rng.nextDouble() * 8,
              h: 4 + _rng.nextDouble() * 6,
              color: _colors[_rng.nextInt(_colors.length)],
              rot: _rng.nextDouble() * 2 * pi,
              rspeed: (_rng.nextDouble() - 0.5) * 0.15,
            ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _ConfettiPainter(_particles, _ctrl.value),
    );
  }
}

class _Particle {
  double x, y, vx, vy, w, h, rot, rspeed;
  final Color color;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.w,
    required this.h,
    required this.color,
    required this.rot,
    required this.rspeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  const _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final px = (p.x + p.vx * t * 60) * size.width;
      final py =
          (p.y + p.vy * t * 60 + 0.5 * 0.0003 * t * t * 3600) * size.height;
      if (py > size.height) continue;

      final alpha =
          (1.0 - (py / size.height).clamp(0.0, 1.0) * 1.2).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rot + p.rspeed * t * 60);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
        Paint()..color = p.color.withOpacity(alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

// ── Screen ───────────────────────────────────────────────────────
class LotteryHistoryScreen extends StatefulWidget {
  final List<Lottery> lotteries;
  final Duration remainingTime;
  final String ekubId;
  final String ekubName;
  final int ekubAmount;
  final int ekubCycle;
  final bool ekubRequest;
  final int ekubersNumber;
  final String nextRoundDate;
  final String nextRoundLotteryType;
  final String nextRoundTime;
  final String serviceCharge;
  final List<BankAccount> bankAccounts;
  final BankAccount? selectedAccount;
  final String? userId;

  const LotteryHistoryScreen({
    super.key,
    required this.lotteries,
    required this.remainingTime,
    required this.ekubId,
    required this.ekubName,
    required this.ekubAmount,
    required this.ekubCycle,
    required this.ekubRequest,
    required this.ekubersNumber,
    required this.nextRoundDate,
    required this.nextRoundLotteryType,
    required this.nextRoundTime,
    required this.serviceCharge,
    required this.bankAccounts,
    this.selectedAccount,
    this.userId,
  });

  @override
  State<LotteryHistoryScreen> createState() => _LotteryHistoryScreenState();
}

class _LotteryHistoryScreenState extends State<LotteryHistoryScreen> {
  late Duration _remaining;
  Timer? _timer;
  BankAccount? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _remaining = widget.remainingTime;
    _selectedAccount = widget.selectedAccount;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining -= const Duration(seconds: 1);
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<User> get _claimableWinningUsers {
    return widget.lotteries
        .expand((lottery) => lottery.users)
        .where(
          (user) =>
              user.userId == widget.userId &&
              user.hasGuarantee &&
              !user.hasClaimed,
        )
        .toList(growable: false);
  }

  void _showWinningDialog(BuildContext context, User user) {
    final claimableUsers = _claimableWinningUsers;
    final currentIndex = claimableUsers.indexWhere(
      (item) => item.equberUserId == user.equberUserId,
    );
    final safeIndex = currentIndex < 0 ? 0 : currentIndex;
    final nextUser = safeIndex + 1 < claimableUsers.length
        ? claimableUsers[safeIndex + 1]
        : null;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => WinningDialog(
        ekubId: widget.ekubId,
        ekubAmount: user.totalLotteryAmount.toString(),
        netLotteryAmount: user.netLotteryAmount.toString(),
        ekubName: widget.ekubName,
        equberUserId: user.equberUserId,
        serviceCharge: widget.serviceCharge,
        bankAccounts: widget.bankAccounts,
        selectedAccount: _selectedAccount,
        onAccountSelected: (acct) => setState(() => _selectedAccount = acct),
        currentSpin: safeIndex + 1,
        totalSpins: claimableUsers.isEmpty ? 1 : claimableUsers.length,
        onNextWinner: nextUser == null
            ? null
            : () {
                if (!mounted) return;
                _showWinningDialog(context, nextUser);
              },
      ),
    );
  }

  Future<void> _handleClaim(User user) async {
    if (user.hasClaimed) return;

    final accessToken = await SecureStorageHelper.getAccessToken() ?? '';
    final apiService = ApiService();

    final data = await apiService.readAll(
      getMyProfile,
      bearerToken: accessToken,
    );

    if (data == null) return;

    if (user.hasGuarantee && !user.hasClaimed) {
      _showWinningDialog(context, user);
      return;
    }

    final rawCompletion = data['data']?['user']?['profileCompletion'];
    final double completion = rawCompletion is num
        ? rawCompletion.toDouble()
        : double.tryParse(rawCompletion?.toString() ?? '') ?? 0.0;

    if (completion >= 100) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuarantorScreen(
            serviceCharge: widget.serviceCharge,
            ekubId: widget.ekubId,
            ekuberUserId: user.equberUserId,
            ekubAmount: widget.ekubAmount,
            ekubCycle: widget.ekubCycle,
            ekubName: widget.ekubName,
            ekubRequest: widget.ekubRequest,
            ekubersNumber: widget.ekubersNumber,
            nextRoundDate: widget.nextRoundDate,
            nextRoundLotteryType: widget.nextRoundLotteryType,
            nextRoundTime: widget.nextRoundTime,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(
            serviceCharge: widget.serviceCharge,
            ekubId: widget.ekubId,
            ekubersUserId: user.equberUserId,
            ekubAmount: widget.ekubAmount,
            ekubCycle: widget.ekubCycle,
            ekubName: widget.ekubName,
            ekubRequest: widget.ekubRequest,
            ekubersNumber: widget.ekubersNumber,
            nextRoundDate: widget.nextRoundDate,
            nextRoundLotteryType: widget.nextRoundLotteryType,
            nextRoundTime: widget.nextRoundTime,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allUsers =
        widget.lotteries.expand((lottery) => lottery.users).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.vibrantGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppKeys.lotteries.tr(context),
          textScaleFactor: 1.0,
          style: const TextStyle(
            color: AppColors.neutralGray,
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: allUsers.isEmpty
          ? _buildNoWinnersYet()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              itemCount: allUsers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = allUsers[index];
                final bool isMine = user.userId == widget.userId;

                final Color statusColor = user.hasTakenEqub
                    ? AppColors.earthySuccessGreen
                    : user.hasClaimed
                        ? AppColors.primary
                        : AppColors.boldSuccessGreen;

                final String statusText = user.hasTakenEqub
                    ? 'Taken'
                    : user.hasClaimed
                        ? 'Claimed'
                        : 'Winner';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: statusColor.withOpacity(0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          user.hasTakenEqub
                              ? Icons.check_circle_rounded
                              : user.hasClaimed
                                  ? Icons.verified_rounded
                                  : Icons.emoji_events_rounded,
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.lotteryNumber,
                              textScaleFactor: 1.0,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.neutralGray,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusText,
                                textScaleFactor: 1.0,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      isMine
                          ? SizedBox(
                              height: 34,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: user.hasTakenEqub
                                      ? AppColors.primary
                                      : user.hasClaimed
                                          ? AppColors.lightGrayBorder
                                          : AppColors.boldSuccessGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                ),
                                onPressed: user.hasClaimed
                                    ? null
                                    : () => _handleClaim(user),
                                child: Text(
                                  user.hasTakenEqub
                                      ? AppKeys.taken.tr(context)
                                      : user.hasClaimed
                                          ? AppKeys.claimed.tr(context)
                                          : AppKeys.claim.tr(context),
                                  textScaleFactor: 1.0,
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F4F3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${AppKeys.round.tr(context)} ${user.round}',
                                textScaleFactor: 1.0,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color.fromRGBO(91, 92, 92, 1),
                                ),
                              ),
                            ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildNoWinnersYet() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: AppColors.vibrantGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: AppColors.vibrantGreen,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No winners yet',
                textScaleFactor: 1.0,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutralGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Winners will appear here once the lottery result is available.',
                textScaleFactor: 1.0,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.neutralGray.withOpacity(0.65),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
