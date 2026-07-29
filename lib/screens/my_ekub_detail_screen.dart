// ignore_for_file: use_build_context_synchronously, deprecated_member_use, empty_catches

import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:confetti/confetti.dart';
import 'package:helloequb/core/api_service_elper.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/models/financial_info.dart';
import 'package:helloequb/screens/join_ekub_detail.dart';
import 'package:helloequb/screens/payment_arrangement_screen.dart';
import 'package:helloequb/screens/pdf_invoice/download_pdf.dart';
import 'package:helloequb/screens/waiting_payment.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/claim_winning_dialog.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/utils/payment_bottom_sheet.dart';
import 'package:helloequb/utils/request_item_popup.dart';
import 'package:helloequb/utils/token_helper.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:helloequb/utils/carousel_card.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../provider/lottery_provider.dart';
import '../utils/secure_storage.dart';
import 'lottery_history_screen.dart';
import 'package:helloequb/utils/style_constants.dart';

// ── Data models (unchanged) ──────────────────────────────────────────────────

class ListItems {
  final String title;
  String subtitle;
  final String userIds;
  ListItems(
      {required this.title, required this.subtitle, required this.userIds});
}

class ApiResp {
  final String status;
  final Data data;
  ApiResp({required this.status, required this.data});
  factory ApiResp.fromJson(Map<String, dynamic> json) =>
      ApiResp(status: json['status'], data: Data.fromJson(json['data']));
}

class Data {
  final List<Lottery> lotteries;
  Data({required this.lotteries});
  factory Data.fromJson(Map<String, dynamic> json) => Data(
        lotteries: (json['lotteries'] as List<dynamic>)
            .map((e) => Lottery.fromJson(e))
            .toList(),
      );
}

class Lottery {
  final List<User> users;
  Lottery({required this.users});
  factory Lottery.fromJson(Map<String, dynamic> json) => Lottery(
        users: (json['users'] as List<dynamic>)
            .map((e) => User.fromJson(e))
            .toList(),
      );
}

class User {
  final String lotteryNumber, equberUserId, userId, userFullName;
  final bool hasGuarantee, hasTakenEqub, hasClaimed;
  final double totalLotteryAmount, netLotteryAmount;
  final int round;
  User({
    required this.lotteryNumber,
    required this.equberUserId,
    required this.userId,
    required this.hasGuarantee,
    required this.totalLotteryAmount,
    required this.netLotteryAmount,
    required this.hasTakenEqub,
    required this.hasClaimed,
    required this.userFullName,
    required this.round,
  });
  factory User.fromJson(Map<String, dynamic> json) => User(
        lotteryNumber: json['lotteryNumber'],
        equberUserId: json['equberUserId'],
        userId: json['userId'],
        hasGuarantee: json['hasGuarantee'],
        totalLotteryAmount: double.parse(json['totalLotteryAmount'].toString()),
        netLotteryAmount: double.parse(json['netLotteryAmount'].toString()),
        hasTakenEqub: json['hasTakenEqub'],
        hasClaimed: json['hasClaimed'],
        userFullName: json['userFullName'],
        round: json['round'],
      );
}

class UserStake {
  final String id;
  final int stake;
  final User user;
  UserStake({required this.id, required this.stake, required this.user});
  factory UserStake.fromJson(Map<String, dynamic> json) => UserStake(
      id: json['id'], stake: json['stake'], user: User.fromJson(json['user']));
}

class EligibleMember {
  final List<UserStake> users;
  EligibleMember({required this.users});
  factory EligibleMember.fromJson(Map<String, dynamic> json) => EligibleMember(
        users: (json['users'] as List<dynamic>)
            .map((e) => UserStake.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CurrentWinner {
  final List<UserStake> users;
  CurrentWinner({required this.users});
  factory CurrentWinner.fromJson(Map<String, dynamic> json) => CurrentWinner(
        users: (json['users'] as List<dynamic>)
            .map((e) => UserStake.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RevealedWinnerItem {
  final int lotteryNumber;
  final String userFullName;

  const RevealedWinnerItem({
    required this.lotteryNumber,
    required this.userFullName,
  });
}

class ResponseModel {
  final List<EligibleMember> eligibleMembers;
  final List<CurrentWinner> currentRoundWinners;
  ResponseModel(
      {required this.eligibleMembers, required this.currentRoundWinners});
  factory ResponseModel.fromJson(Map<String, dynamic> json) => ResponseModel(
        eligibleMembers: (json['eligibleMembers'] as List<dynamic>)
            .map((e) => EligibleMember.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentRoundWinners: (json['currentRoundWinners'] as List<dynamic>)
            .map((e) => CurrentWinner.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

String _firstAndMiddleName(String? name) {
  final parts = (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  return parts.take(2).join(' ');
}

class PaymentResponse {
  final String status;
  final int equbRound;
  final List<Payment> payments;
  PaymentResponse(
      {required this.status, required this.equbRound, required this.payments});
  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    final paymentsJson = (json['data']?['payments'] as List?) ?? const [];
    return PaymentResponse(
      status: json['status'],
      equbRound: json['data']['equbRound'],
      payments: List<Payment>.from(paymentsJson
          .map((p) => Payment.fromJson(Map<String, dynamic>.from(p as Map)))),
    );
  }
}

class Payment {
  final String name, id, lotteryNumber, equbersId;
  final int totalPaid, paidRound;
  final double amountPaid, equbAmount;
  final bool paid, isGroup;
  final Request? request;
  Payment({
    required this.name,
    required this.id,
    required this.lotteryNumber,
    required this.totalPaid,
    required this.amountPaid,
    required this.equbersId,
    required this.paidRound,
    required this.equbAmount,
    required this.paid,
    required this.isGroup,
    this.request,
  });
  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        name: _firstAndMiddleName(json['name']?.toString()),
        id: json['id']?.toString() ?? '',
        lotteryNumber: json['lotteryNumber']?.toString() ?? '',
        equbersId: json['equberUserId']?.toString() ?? '',
        totalPaid: json['totalPaid'] is int
            ? json['totalPaid']
            : int.parse(json['totalPaid'].toString()),
        paidRound: int.tryParse(json['paidRound'].toString()) ?? 0,
        amountPaid: double.parse(json['amountPaid'].toString())
                    .toStringAsFixed(2) ==
                'NaN'
            ? 0.0
            : double.parse(
                double.parse(json['amountPaid'].toString()).toStringAsFixed(2)),
        equbAmount: double.parse(json['equbAmount'].toString())
                    .toStringAsFixed(2) ==
                'NaN'
            ? 0.0
            : double.parse(
                double.parse(json['equbAmount'].toString()).toStringAsFixed(2)),
        paid: json['paid'] == true,
        isGroup: json['isGroup'] == true,
        request:
            json['request'] != null ? Request.fromJson(json['request']) : null,
      );
}

class Request {
  final String id, itemName, description, equberId, state;
  final double amount;
  final DateTime createdAt, updatedAt;
  Request({
    required this.id,
    required this.itemName,
    required this.description,
    required this.amount,
    required this.equberId,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
  });
  factory Request.fromJson(Map<String, dynamic> json) => Request(
        id: json['id'],
        itemName: json['itemName'],
        description: json['description'],
        amount: double.parse(json['amount'].toString()),
        equberId: json['equberId'],
        state: json['state'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

// ── Screen ───────────────────────────────────────────────────────────────────

class MyEkubDetailScreen extends StatefulWidget {
  final String ekubName, ekubId;
  final int ekubAmount, ekubersNumber, ekubCycle;
  final String nextRoundDate, nextRoundTime;
  final bool ekubRequest;
  final String nextRoundLotteryType, serviceCharge, ekubType;
  String? navigateFrom;

  MyEkubDetailScreen({
    super.key,
    required this.ekubAmount,
    required this.ekubId,
    required this.ekubName,
    required this.ekubersNumber,
    required this.ekubCycle,
    required this.nextRoundDate,
    required this.nextRoundTime,
    required this.ekubRequest,
    required this.nextRoundLotteryType,
    required this.serviceCharge,
    this.navigateFrom,
    required this.ekubType,
  });

  @override
  State<MyEkubDetailScreen> createState() => _MyEkubDetailScreenState();
}

class _MyEkubDetailScreenState extends State<MyEkubDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  DateTime targetDateTime = DateTime.now().add(const Duration(minutes: 1));
  Duration remainingTime = const Duration(minutes: 2);
  Timer? _timer;
  Timer? _scheduleSyncTimer;
  Duration _timeOffset = Duration.zero;

  /// counting → revealing → idle
  bool _isRevealing = false;
  bool _revealStarted = false;
  bool _showNoWinnerState = false;

  int? _currentWinnerNumber;
  List<int> _pendingWinnerNumbers = [];
  int _spinGeneration = 0; // bumps LotteryWheel key so it always remounts & spins
  final Set<int> _revealedWinnerNumbers = {};
  final List<RevealedWinnerItem> _revealedCurrentDrawWinners = [];

  /// False from 1 min before draw until all winner spins finish.
  bool _allDrawWinnersSpun = false;

  /// After a reveal finishes, skip early-draw hold so next-round time can stick.
  bool _suppressEarlyDrawHold = false;

  /// Server may advance nextRoundDate after an early draw; apply after spin.
  DateTime? _postRevealTarget;

  /// True while holding a short local countdown after an early backend draw.
  /// Winners stay hidden until this window hits 0:00 and the wheel spins.
  bool _holdingEarlyDrawReveal = false;

  /// Current-draw lottery numbers that must stay on the spinner until spun.
  /// (Backend may already mark them hasWonEqub during the early-draw window.)
  final Set<int> _wheelKeepWinnerNumbers = {};

  List<dynamic> currentRoundWinnersSocket = [];
  List<dynamic> eligibleMembersSocket = [];
  List<dynamic> equbEligibleMembersSocket = [];

  bool _socketListenersAttached = false;

  final Dio dio = Dio();
  final DataController dataController = DataController();
  final ApiService apiService = ApiService();

  List<Payment> _payments = [];
  List<Lottery> _lotteries = [];
  List<BankAccount> bankAccounts = [];
  BankAccount? selectedAccount;

  bool _isLoading = true;
  bool _hasNavigated = false;
  bool _isOpeningLotteryHistory = false;
  bool isRefreshed = false;
  bool isLoading = true;

  List<String> elligibleUsersList = [];
  List<String> elligibleUsersLotteryList = [];
  List<String> winnersList = [];
  List<String> currentWinnersList = [];
  List<String> currentWinnersIdList = [];

  List<String> lotteryNumbers = [];
  List<double> paidPerEachLottery = [];
  List<String> equbUserIds = [];

  String? ekubRound, totalPaid, equbers, userId;

  List<ListItems> listItemss = [];
  List<ListItem> listItems = [];

  IO.Socket? socket;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<LotteryProvider>().fetchLotteries(widget.ekubId);
    });

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    try {
      final updatedDateTime =
          '${widget.nextRoundDate.substring(0, 11)}${widget.nextRoundTime}:00Z';
      targetDateTime = DateTime.parse(updatedDateTime);
    } catch (_) {}

    initializePage();
    getListOfFinancialInfo();
    tokenUpdate();

    socket = IO.io(socketServer, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _initSocketListeners();

    getEkubLotteries();
    getEkubPayments();
    _startCountdownSystem();
  }

  @override
  void dispose() {
    _scheduleSyncTimer?.cancel();
    _timer?.cancel();
    _tabController.dispose();
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }

  /// When more than 2 days remain, show every round slot (1..total rounds)
  /// so the wheel looks fully filled. Within 2 days (and during reveal), show
  /// the real joined-equber list.
  ///
  /// Note: [ekubCycle] carries API `numberOfEqubers` (total rounds).
  /// [ekubersNumber] is the joined equbers count.
  List<int> _wheelSlotNumbers(LotteryProvider provider) {
    final showAllRoundSlots = remainingTime > const Duration(days: 2) &&
        !_isRevealing &&
        !_holdingEarlyDrawReveal &&
        _currentWinnerNumber == null &&
        _wheelKeepWinnerNumbers.isEmpty;

    if (showAllRoundSlots) {
      final totalRounds = widget.ekubCycle;
      if (totalRounds <= 0) return const <int>[];
      return List<int>.generate(totalRounds, (i) => i + 1);
    }

    final keepOnWheel = {
      if (_currentWinnerNumber != null) _currentWinnerNumber!,
      ..._pendingWinnerNumbers,
      // Keep early-draw winners on the spinner until their result spins.
      ..._wheelKeepWinnerNumbers
          .where((n) => !_revealedWinnerNumbers.contains(n)),
    };

    final numbers = provider.eligibleMembers
        .where((m) =>
            !m.hasWonEqub || keepOnWheel.contains(m.lotteryNumber))
        .map((m) => m.lotteryNumber)
        .where((n) => n > 0)
        .where((n) =>
            !_revealedWinnerNumbers.contains(n) || keepOnWheel.contains(n))
        .toSet()
        .toList();

    for (final n in keepOnWheel) {
      if (n > 0 && !numbers.contains(n)) numbers.add(n);
    }
    numbers.sort();
    return numbers;
  }

  /// Latest draw only: highest winRound (and matching winningDate cluster).
  List<int> _latestDrawLotteryNumbers(List<dynamic> raw) {
    if (raw.isEmpty) return [];

    DateTime? latest;
    for (final w in raw) {
      final d = DateTime.tryParse(w['winningDate']?.toString() ?? '');
      if (d != null && (latest == null || d.isAfter(latest))) latest = d;
    }

    var rows = raw;
    if (latest != null) {
      rows = raw.where((w) {
        final d = DateTime.tryParse(w['winningDate']?.toString() ?? '');
        return d != null &&
            d.difference(latest!).abs() <= const Duration(minutes: 3);
      }).toList();
    } else {
      var maxRound = 0;
      for (final w in raw) {
        final r = int.tryParse(
                (w['winRound'] ?? w['generalWinRound'])?.toString() ?? '') ??
            0;
        if (r > maxRound) maxRound = r;
      }
      if (maxRound > 0) {
        rows = raw.where((w) {
          final r = int.tryParse(
                  (w['winRound'] ?? w['generalWinRound'])?.toString() ?? '') ??
              0;
          return r == maxRound;
        }).toList();
      }
    }

    final out = <int>{};
    for (final w in rows) {
      final n = int.tryParse(w['lotteryNumber']?.toString() ?? '');
      if (n != null && n > 0 && !_revealedWinnerNumbers.contains(n)) {
        out.add(n);
      }
    }
    return out.toList()..sort();
  }

  RevealedWinnerItem _winnerDisplayForNumber(int lotteryNumber) {
    for (final raw in currentRoundWinnersSocket) {
      final n = int.tryParse(raw['lotteryNumber']?.toString() ?? '');
      if (n == lotteryNumber) {
        return RevealedWinnerItem(
          lotteryNumber: lotteryNumber,
          userFullName: _firstAndMiddleName(raw['userFullName']?.toString()),
        );
      }
    }

    return RevealedWinnerItem(
      lotteryNumber: lotteryNumber,
      userFullName: '',
    );
  }

  // ── Countdown + reveal (simple) ────────────────────────────────────────────

  Future<void> _startCountdownSystem() async {
    await _syncClockAndSchedule(forceTarget: true);
    if (!mounted) return;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _scheduleSyncTimer?.cancel();
    _scheduleSyncTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _syncClockAndSchedule(),
    );
  }

  DateTime get _nowServer => DateTime.now().add(_timeOffset);

  bool get _shouldHideLotteryHistoryButton =>
      _holdingEarlyDrawReveal ||
      _isRevealing ||
      (!_allDrawWinnersSpun &&
          remainingTime <= const Duration(minutes: 1));

  void _onTick() {
    if (!mounted || _isRevealing) return;

    final left = targetDateTime.difference(_nowServer);
    final clamped = left.isNegative ? Duration.zero : left;

    if (clamped != remainingTime) {
      setState(() => remainingTime = clamped);
    }

    // Final minute of the next draw: allow early-draw hold again and hide history.
    if (left > Duration.zero &&
        left <= const Duration(minutes: 1) &&
        !_holdingEarlyDrawReveal) {
      if (_suppressEarlyDrawHold || _allDrawWinnersSpun) {
        setState(() {
          _suppressEarlyDrawHold = false;
          _allDrawWinnersSpun = false;
        });
      }
    }

    // Don't re-start reveal while applying / holding next-round sync.
    if (left <= Duration.zero &&
        !_revealStarted &&
        !_suppressEarlyDrawHold) {
      _beginReveal();
    }
  }

  DateTime? _parseEqubTarget(String? date, String? time) {
    if (date == null || time == null || date.length < 11) return null;
    try {
      return DateTime.parse('${date.substring(0, 11)}$time:00Z');
    } catch (_) {
      return null;
    }
  }

  /// True when left time is "N days + less than 1 minute" (early-draw artifact
  /// after nextRoundDate jumps to the next cycle — daily, weekly, etc.).
  bool _isDaysPlusSubMinute(Duration left) {
    if (left.inDays < 1) return false;
    final subDay = left - Duration(days: left.inDays);
    return subDay < const Duration(minutes: 1);
  }

  /// Pick a local 0:00 deadline of at most 1 minute for the early-draw hold.
  DateTime _localRevealDeadline(DateTime? preferred) {
    final now = _nowServer;
    if (preferred != null) {
      final left = preferred.difference(now);
      if (left > Duration.zero && left <= const Duration(minutes: 1)) {
        return preferred;
      }
      if (left <= Duration.zero && left > const Duration(minutes: -1)) {
        // Already at/ past scheduled time — spin ASAP.
        return now;
      }
    }
    // Unknown exact second: count down almost 1 minute, then spin.
    return now.add(const Duration(seconds: 55));
  }

  Future<void> _prefetchWheelKeepWinners() async {
    final winners = await _fetchCurrentDrawWinners();
    if (!mounted) return;
    setState(() {
      _wheelKeepWinnerNumbers
        ..addAll(winners)
        ..addAll(_latestDrawLotteryNumbers(currentRoundWinnersSocket));
    });
  }

  Future<void> _armEarlyDrawHold({
    required DateTime nextRoundTarget,
    DateTime? preferredLocalReveal,
  }) async {
    final localRevealAt =
        _localRevealDeadline(preferredLocalReveal ?? targetDateTime);
    final left = localRevealAt.difference(_nowServer);
    final clamped = left.isNegative ? Duration.zero : left;

    _postRevealTarget = nextRoundTarget;
    _holdingEarlyDrawReveal = true;
    _allDrawWinnersSpun = false;
    _revealedCurrentDrawWinners.clear();

    // Load winners onto the spinner now — hide results only, not wheel slots.
    await _prefetchWheelKeepWinners();

    if (!mounted) return;
    setState(() {
      targetDateTime = localRevealAt;
      remainingTime = clamped;
      isLoading = false;
      // Hide draw *results* until spin — keep numbers on the wheel.
      _revealStarted = false;
      _showNoWinnerState = false;
      _currentWinnerNumber = null;
      _pendingWinnerNumbers = [];
    });

    if (clamped == Duration.zero && !_isRevealing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_revealStarted && !_isRevealing) {
          _beginReveal();
        }
      });
    }
  }

  Future<void> _syncClockAndSchedule({bool forceTarget = false}) async {
    if (!mounted || _isRevealing) return;
    try {
      final requestTime = DateTime.now();
      final timeRes = await dio.get(getServerTimeUrl);
      if (timeRes.statusCode == 200) {
        final responseTime = DateTime.now();
        final serverTime = DateTime.parse(timeRes.data['date']);
        final rtt = responseTime.difference(requestTime).inMilliseconds ~/ 2;
        _timeOffset =
            serverTime.add(Duration(milliseconds: rtt)).difference(DateTime.now());
      }

      final token = await SecureStorageHelper.getAccessToken() ?? '';
      final res = await dio.get(
        '$ekubsUrl/${widget.ekubId}',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (res.statusCode != 200 && res.statusCode != 201) return;

      final equb = res.data['data']['equb'];
      final newTarget = _parseEqubTarget(
        equb['nextRoundDate']?.toString(),
        equb['nextRoundTime']?.toString(),
      );
      if (newTarget == null || !mounted) return;

      final widgetTarget =
          _parseEqubTarget(widget.nextRoundDate, widget.nextRoundTime);
      final serverLeft = newTarget.difference(_nowServer);
      final jumpedAhead =
          newTarget.isAfter(targetDateTime.add(const Duration(minutes: 5)));
      final jumpedPastWidget = widgetTarget != null &&
          newTarget.isAfter(widgetTarget.add(const Duration(minutes: 5)));

      DateTime? preferredLocal;
      if (widgetTarget != null) {
        final wLeft = widgetTarget.difference(_nowServer);
        if (wLeft <= const Duration(minutes: 1) &&
            wLeft > const Duration(minutes: -1)) {
          preferredLocal = widgetTarget;
        }
      }
      if (preferredLocal == null) {
        final cLeft = targetDateTime.difference(_nowServer);
        if (cLeft <= const Duration(minutes: 1) &&
            cLeft > const Duration(minutes: -1)) {
          preferredLocal = targetDateTime;
        }
      }
      // "N days + X seconds" → X seconds is the real time left until local 0:00.
      if (preferredLocal == null && _isDaysPlusSubMinute(serverLeft)) {
        final subDay = serverLeft - Duration(days: serverLeft.inDays);
        preferredLocal = _nowServer.add(subDay);
      }

      final preferredLeft = preferredLocal?.difference(_nowServer);
      final inLastMinute = preferredLeft != null &&
          preferredLeft <= const Duration(minutes: 1) &&
          preferredLeft > const Duration(minutes: -1);

      // Early draw: next round already advanced (N days + seconds).
      // Hold a <1 min local countdown, hide winners, then spin → real next left.
      // Skip after a completed reveal until the next last-minute window.
      if (!_suppressEarlyDrawHold &&
          !_holdingEarlyDrawReveal &&
          (jumpedAhead ||
              jumpedPastWidget ||
              _isDaysPlusSubMinute(serverLeft)) &&
          (inLastMinute ||
              _isDaysPlusSubMinute(serverLeft) ||
              (forceTarget && await _hasPendingRecentDrawReveal()))) {
        await _armEarlyDrawHold(
          nextRoundTarget: newTarget,
          preferredLocalReveal: preferredLocal,
        );
        return;
      }

      // Already holding — don't overwrite with the far next-round time.
      if (_holdingEarlyDrawReveal) {
        _postRevealTarget = newTarget;
        return;
      }

      if (forceTarget || newTarget != targetDateTime) {
        setState(() {
          targetDateTime = newTarget;
          final left = targetDateTime.difference(_nowServer);
          remainingTime = left.isNegative ? Duration.zero : left;
          isLoading = false;
          if (remainingTime > Duration.zero) {
            _revealStarted = false;
            _showNoWinnerState = false;
            // Next round is live — hide history until the last minute again.
            // Keep the floating winners stack until history tap / leave page.
            if (_suppressEarlyDrawHold &&
                remainingTime > const Duration(minutes: 1)) {
              _allDrawWinnersSpun = false;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('schedule sync failed: $e');
    }
  }

  /// Recent winners whose draw should still be revealed on this visit.
  Future<bool> _hasPendingRecentDrawReveal() async {
    final token = await SecureStorageHelper.getAccessToken() ?? '';
    final headers = Options(headers: {'Authorization': 'Bearer $token'});

    List<dynamic> raw = currentRoundWinnersSocket;
    try {
      final res =
          await dio.get(getEligibleUsers + widget.ekubId, options: headers);
      if (res.statusCode == 200 || res.statusCode == 201) {
        raw = (res.data['data']?['currentRoundWinners'] as List?) ?? raw;
        if (raw.isNotEmpty) {
          currentRoundWinnersSocket = List<dynamic>.from(raw);
        }
      }
    } catch (_) {}

    final nums = _latestDrawLotteryNumbers(raw);
    if (nums.isEmpty) return false;

    DateTime? latestWin;
    for (final w in raw) {
      final d = DateTime.tryParse(w['winningDate']?.toString() ?? '');
      if (d != null && (latestWin == null || d.isAfter(latestWin))) {
        latestWin = d;
      }
    }

    if (latestWin == null) return true;

    final age = _nowServer.difference(latestWin.toUtc());
    return age >= const Duration(minutes: -2) &&
        age <= const Duration(minutes: 5);
  }

  Future<void> _beginReveal() async {
    if (_revealStarted || _isRevealing) return;
    _revealStarted = true;
    _isRevealing = true;
    _allDrawWinnersSpun = false;
    _timer?.cancel();

    if (mounted) {
      setState(() {
        remainingTime = Duration.zero;
        _showNoWinnerState = false;
      });
    }

    List<int> winners = _wheelKeepWinnerNumbers.isNotEmpty
        ? _wheelKeepWinnerNumbers
            .where((n) => !_revealedWinnerNumbers.contains(n))
            .toList()
        : <int>[];

    if (winners.isEmpty) {
      for (var i = 0; i < 15; i++) {
        if (!mounted) return;
        winners = await _fetchCurrentDrawWinners();
        debugPrint('Reveal attempt ${i + 1}: $winners');
        if (winners.isNotEmpty) break;
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (!mounted) return;

    if (winners.isEmpty) {
      _holdingEarlyDrawReveal = false;
      setState(() {
        _isRevealing = false;
        _showNoWinnerState = true;
        _revealStarted = false;
        _suppressEarlyDrawHold = true;
        _revealedCurrentDrawWinners.clear();
      });
      _applyPostRevealTarget();
      _restartCountdownTimer();
      return;
    }

    _wheelKeepWinnerNumbers.addAll(winners);

    // Refresh segments, then spin (LotteryWheel remounts via key).
    // Keep winners on the wheel across this refresh (hasWonEqub may be true).
    try {
      await context.read<LotteryProvider>().fetchLotteries(widget.ekubId);
    } catch (_) {}

    if (!mounted) return;

    _holdingEarlyDrawReveal = false;
    setState(() {
      _revealedCurrentDrawWinners.clear();
      _pendingWinnerNumbers = List<int>.from(winners);
      _currentWinnerNumber = _pendingWinnerNumbers.removeAt(0);
      _spinGeneration++;
      remainingTime = Duration.zero;
      _showNoWinnerState = false;
    });
  }

  Future<List<int>> _fetchCurrentDrawWinners() async {
    final token = await SecureStorageHelper.getAccessToken() ?? '';
    final headers = Options(headers: {'Authorization': 'Bearer $token'});

    // Primary: live current-round winners (backend draws ~1 min early).
    try {
      final res =
          await dio.get(getEligibleUsers + widget.ekubId, options: headers);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final raw =
            (res.data['data']?['currentRoundWinners'] as List?) ?? const [];
        currentRoundWinnersSocket = List<dynamic>.from(raw);
        final nums = _latestDrawLotteryNumbers(raw);
        if (nums.isNotEmpty) {
          winnersList
            ..clear()
            ..addAll(nums.map((e) => e.toString()));
          return nums;
        }
      }
    } catch (e) {
      debugPrint('winner poll (lottery) failed: $e');
    }

    // Socket cache from equb-eligible (still hidden until 0:00).
    if (currentRoundWinnersSocket.isNotEmpty) {
      final nums = _latestDrawLotteryNumbers(currentRoundWinnersSocket);
      if (nums.isNotEmpty) return nums;
    }

    return [];
  }

  void _onWheelSpinComplete() {
    if (_currentWinnerNumber != null) {
      _revealedWinnerNumbers.add(_currentWinnerNumber!);
      _revealedCurrentDrawWinners.add(
        _winnerDisplayForNumber(_currentWinnerNumber!),
      );
      _wheelKeepWinnerNumbers.remove(_currentWinnerNumber!);
    }

    if (_pendingWinnerNumbers.isEmpty) {
      setState(() {
        _currentWinnerNumber = null;
        _isRevealing = false;
        _allDrawWinnersSpun = true;
        _suppressEarlyDrawHold = true;
        _wheelKeepWinnerNumbers.clear();
      });
      getEkubLotteries();
      context.read<LotteryProvider>().fetchLotteries(widget.ekubId);
      _applyPostRevealTarget();
      _restartCountdownTimer();
      return;
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _currentWinnerNumber = _pendingWinnerNumbers.removeAt(0);
        _spinGeneration++;
        remainingTime = Duration.zero;
      });
    });
  }

  Future<void> _applyPostRevealTarget() async {
    final cachedNext = _postRevealTarget;
    _postRevealTarget = null;
    _holdingEarlyDrawReveal = false;
    _wheelKeepWinnerNumbers.clear();
    _suppressEarlyDrawHold = true;
    winnersList.clear();

    DateTime? next = cachedNext;
    try {
      final token = await SecureStorageHelper.getAccessToken() ?? '';
      final res = await dio.get(
        '$ekubsUrl/${widget.ekubId}',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final equb = res.data['data']['equb'];
        next = _parseEqubTarget(
              equb['nextRoundDate']?.toString(),
              equb['nextRoundTime']?.toString(),
            ) ??
            next;
      }
    } catch (e) {
      debugPrint('post-reveal schedule fetch failed: $e');
    }

    if (!mounted) return;

    if (next == null) {
      await _syncClockAndSchedule(forceTarget: true);
      return;
    }

    setState(() {
      targetDateTime = next!;
      final left = targetDateTime.difference(_nowServer);
      remainingTime = left.isNegative ? Duration.zero : left;
      isLoading = false;
      _revealStarted = false;
      _showNoWinnerState = false;
      // Next round countdown is live — hide history until the next last-minute
      // window. Keep floating winners until history tap / leave page.
      if (remainingTime > const Duration(minutes: 1)) {
        _allDrawWinnersSpun = false;
      }
    });
  }

  void _restartCountdownTimer() {
    if (_isRevealing) return;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _initSocketListeners() {
    if (_socketListenersAttached || socket == null) return;
    _socketListenersAttached = true;

    socket!.on('equb-lottery', (data) {
      try {
        if (data is! Map) return;
        if (data['equbId']?.toString() != widget.ekubId) return;
        _syncClockAndSchedule();
      } catch (_) {}
    });

    socket!.on('equb-eligible', (data) {
      if (data is! Map || data['status'] != 'success' || !mounted) return;
      final winners = data['data']?['currentRoundWinners']?.toList() ?? [];
      setState(() {
        eligibleMembersSocket =
            data['data']?['eligibleMembers']?.toList() ?? [];
        currentRoundWinnersSocket = winners;
        equbEligibleMembersSocket =
            data['data']?['equbEligibleMembers']?.toList() ?? [];
        // Keep early-draw winners on the spinner; still hide result UI.
        if (_holdingEarlyDrawReveal || remainingTime <= const Duration(minutes: 2)) {
          _wheelKeepWinnerNumbers
              .addAll(_latestDrawLotteryNumbers(winners));
        }
      });
      // Cache only — never spin before 0:00.
    });

    socket!.connect();
  }

  Future<void> getMyEkubs(String id) async {
    await _syncClockAndSchedule(forceTarget: true);
  }

  Future<void> getElligbleUsers() async {
    // Kept for "Check again" — runs the same reveal path.
    if (remainingTime > Duration.zero) {
      await _syncClockAndSchedule(forceTarget: true);
      return;
    }
    _revealStarted = false;
    await _beginReveal();
  }

  Future<void> tokenUpdate() async {
    TokenHelper.checkTokenExpiration(
      context: context,
      dio: dio,
      refreshTokenUrl: refreshTokenUrl,
      refreshToken: (await SecureStorageHelper.getRefreshToken()) ?? '',
    );
  }

  void _handleTabSelection() => setState(() {});
  void sendMessage(String message) => socket?.emit('message', message);

  Future<void> getEkubLotteries() async {
    String token = await SecureStorageHelper.getAccessToken() ?? '';
    try {
      final res = await dio.get(ekubLotteriesUrl + widget.ekubId,
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      if (res.statusCode == 200 || res.statusCode == 201) {
        List<Lottery> lotteries =
            (res.data['data']['lotteries'] as List<dynamic>)
                .map((e) => Lottery.fromJson(e))
                .toList();
        lotteries.sort((a, b) {
          final aR = a.users.isNotEmpty ? a.users.first.round : 0;
          final bR = b.users.isNotEmpty ? b.users.first.round : 0;
          return aR.compareTo(bR);
        });
        setState(() {
          _lotteries = lotteries;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> getEkubPayments() async {
    String token = await SecureStorageHelper.getAccessToken() ?? '';
    try {
      final res = await dio.get(ekubPaymentsUrl + widget.ekubId,
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      if (res.statusCode == 200 || res.statusCode == 201) {
        ekubRound = res.data['data']['equbRound'].toString();
        totalPaid = res.data['data']['equbersPaid'].toString();
        equbers = res.data['data']['equbers'].toString();

        lotteryNumbers.clear();
        paidPerEachLottery.clear();
        equbUserIds.clear();

        final List<Payment> payments = ((res.data['data']['payments']
                    as List?) ??
                [])
            .map((e) => Payment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        for (var p in payments) {
          lotteryNumbers.add(p.lotteryNumber);
          paidPerEachLottery.add(p.equbAmount);
          equbUserIds.add(p.equbersId);
        }
        setState(() {
          _payments = payments;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> getListOfFinancialInfo() async {
    String token = await SecureStorageHelper.getAccessToken() ?? '';
    final data = await apiService.readAll(addFinancialUrl, bearerToken: token);
    if (data != null && data['data']?['bankAccounts']?.isNotEmpty) {
      final responseData = ResponseData.fromJson(data);
      setState(() => bankAccounts = responseData.bankAccounts);
    }
  }

  Future<void> initializePage() async {
    await Future.delayed(const Duration(seconds: 2));
    userId = await SecureStorageHelper.getUserId();
    if (widget.navigateFrom == 'fortune' && !isRefreshed) {
      getMyEkubs(widget.ekubId);
      setState(() => isRefreshed = true);
    }
  }

  Future<void> _handleRefresh() async {
    listItems = [];
    listItemss = [];
    if (remainingTime > const Duration(minutes: 2)) {
      getEkubPayments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("You can't refresh when less than 2 minutes remaining.")),
      );
    }
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> _openLotteryHistory() async {
    if (_isOpeningLotteryHistory) return;

    setState(() {
      _isOpeningLotteryHistory = true;
      _revealedCurrentDrawWinners.clear();
    });
    await getEkubLotteries();
    await getListOfFinancialInfo();

    if (!mounted) return;

    setState(() => _isOpeningLotteryHistory = false);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LotteryHistoryScreen(
          lotteries: _lotteries,
          remainingTime: remainingTime,
          ekubId: widget.ekubId,
          ekubName: widget.ekubName,
          ekubAmount: widget.ekubAmount,
          ekubCycle: widget.ekubCycle,
          ekubRequest: widget.ekubRequest,
          ekubersNumber: widget.ekubersNumber,
          nextRoundDate: widget.nextRoundDate,
          nextRoundLotteryType: widget.nextRoundLotteryType,
          nextRoundTime: widget.nextRoundTime,
          serviceCharge: widget.serviceCharge,
          bankAccounts: bankAccounts,
          selectedAccount: selectedAccount,
          userId: userId,
        ),
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void showWinningDialog(
    BuildContext context,
    String ekubId,
    String ekubAmount,
    String netLotteryAmount,
    String ekubName,
    String equberUserId,
    String serviceCharge,
  ) {
    ConfettiController cc =
        ConfettiController(duration: const Duration(seconds: 3));
    cc.play();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => WinningDialog(
        ekubId: ekubId,
        ekubAmount: ekubAmount,
        netLotteryAmount: netLotteryAmount,
        ekubName: ekubName,
        equberUserId: equberUserId,
        serviceCharge: serviceCharge,
        bankAccounts: bankAccounts,
        selectedAccount: selectedAccount,
        onAccountSelected: (BankAccount? a) =>
            setState(() => selectedAccount = a),
      ),
    );
  }

  void _showPaymentsBottomSheet(BuildContext context, List<Payment> payments) {
    final total =
        payments.fold<double>(0, (s, p) => s + (p.equbAmount * p.paidRound));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentSummarySheet(
          payments: payments, total: total, context: context),
    );
  }

  void _showPaymentArrangementDialog() {
    listItemss.clear();
    listItems.clear();
    final Set<String> seen = {};
    for (int i = 0; i < lotteryNumbers.length; i++) {
      if (seen.add(lotteryNumbers[i])) {
        listItemss.add(ListItems(
            title: lotteryNumbers[i],
            subtitle: paidPerEachLottery[i].toString(),
            userIds: equbUserIds[i]));
        listItems.add(ListItem(
            title: lotteryNumbers[i],
            subtitle: paidPerEachLottery[i].toString()));
      }
    }
    double expected =
        listItemss.fold(0, (s, e) => s + double.parse(e.subtitle));
    showDialog(
      context: context,
      builder: (_) => PaymentArragement(
        selectedJoinOption: listItems,
        selectedJoinOptions: listItemss,
        ekubAmount: widget.ekubAmount.toString(),
        ekubId: widget.ekubId,
        ekubName: widget.ekubName,
        ekubRound: ekubRound,
        round: ekubRound,
        expectedAmount: expected,
        type: 'payment',
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final days = remainingTime.inDays;
    final hours = remainingTime.inHours % 24;
    final minutes = remainingTime.inMinutes % 60;
    final seconds = remainingTime.inSeconds % 60;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: _buildHeader(context)),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPaymentTab(),
                  _buildLotteriesTab(days, hours, minutes, seconds),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1DB954), Color(0xFF14833B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.ekubName,
                  style: AppTextStyles.poppins70020.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _HeaderChipButton(
                label: AppKeys.pendingPayments.tr(context),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            WaitingEkubsPayment(ekubId: widget.ekubId))),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (v) {
                  if (v == 'report') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DownloadPdf(
                                type: widget.ekubId,
                                date: DateTime.now().toIso8601String(),
                                image: '',
                                result: 'result')));
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                      value: 'report', child: Text(AppKeys.report.tr(context))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          CarouselCard(
            amount: numberFormat.format(widget.ekubAmount),
            ekubName: widget.ekubName,
            ekubersNumber: widget.ekubersNumber.toString(),
            cycle: widget.ekubCycle.toString(),
            total: _payments.fold<double>(
                0, (s, p) => s + (p.equbAmount * p.paidRound)),
            buttonShow: false,
          ),
        ],
      ),
    );
  }

  // ── TabBar ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.vibrantGreen,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.vibrantGreen,
        labelStyle: AppTextStyles.poppins60014,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: AppKeys.payment.tr(context)),
          Tab(text: AppKeys.lotteries.tr(context)),
        ],
      ),
    );
  }

  // ── Payment Tab ────────────────────────────────────────────────────────────

  Widget _buildPaymentTab() {
    return RefreshIndicator(
      color: AppColors.vibrantGreen,
      onRefresh: _handleRefresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildNextRoundRow(),
          const SizedBox(height: 16),
          _buildMakePaymentButton(),
          const SizedBox(height: 20),
          _buildSectionHeader(
            left: AppKeys.viewPayments.tr(context),
            right: '${AppKeys.round.tr(context)} $ekubRound',
            onLeftTap: () => _showPaymentsBottomSheet(context, _payments),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child:
                      SpinKitFadingCircle(color: AppColors.primary, size: 48)),
            )
          else if (_payments.isEmpty)
            _buildEmptyState()
          else
            ..._payments.map((item) => _buildPaymentCard(item)).toList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNextRoundRow() {
    return Row(
      children: [
        _InfoPill(
          icon: Icons.calendar_today_rounded,
          label: AppKeys.nextRound.tr(context),
          value: widget.ekubRequest
              ? '${widget.nextRoundLotteryType.toUpperCase()} / ${DateFormat('MMM d').format(targetDateTime)}'
              : DateFormat('MMM d').format(targetDateTime),
        ),
      ],
    );
  }

  Widget _buildMakePaymentButton() {
    return Material(
      elevation: 4,
      shadowColor: AppColors.vibrantGreen.withOpacity(0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _showPaymentArrangementDialog,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1DB954), Color(0xFF14833B)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.payment_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                AppKeys.makePayment.tr(context),
                style: AppTextStyles.poppins60015.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String left,
    required String right,
    VoidCallback? onLeftTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onLeftTap,
          child: Row(
            children: [
              Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(
                left,
                style: AppTextStyles.poppins70014.copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new_rounded,
                  size: 14, color: AppColors.primary),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            right,
            style: AppTextStyles.poppins60013.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(Payment item) {
    final bool isPaid = item.amountPaid == item.equbAmount &&
        item.paidRound >= int.parse(ekubRound ?? '0');

    return GestureDetector(
      onTap: () => LotteryDetailBottomSheet.show(
        context,
        lottery: item.lotteryNumber,
        round: item.paidRound,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
          border: Border.all(
            color: isPaid
                ? AppColors.earthySuccessGreen.withOpacity(0.4)
                : AppColors.crimsonRed.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.earthySuccessGreen.withOpacity(0.12)
                      : AppColors.crimsonRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.lotteryNumber,
                      style: AppTextStyles.poppins70018.copyWith(
                        color: const Color(0xFF2D2D2D),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppKeys.lottery.tr(context),
                      style: AppTextStyles.poppins40010.copyWith(
                        color: Colors.grey[600],
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.poppins60014.copyWith(color: const Color(0xFF2D2D2D)),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.poppins40013.copyWith(color: Colors.grey[600]),
                        children: [
                          TextSpan(
                              text: numberFormat.format(
                                  item.amountPaid < 0 ? 0 : item.amountPaid),
                              style: AppTextStyles.poppins60014.copyWith(color: Color(0xFF2D2D2D))),
                          const TextSpan(text: ' / '),
                          TextSpan(
                              text:
                                  '${numberFormat.format(item.equbAmount)} ETB'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppColors.earthySuccessGreen.withOpacity(0.12)
                          : AppColors.crimsonRed.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPaid
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 12,
                          color: isPaid
                              ? AppColors.earthySuccessGreen
                              : AppColors.crimsonRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPaid
                              ? AppKeys.paid.tr(context)
                              : AppKeys.notPaid.tr(context),
                          style: AppTextStyles.poppins60011,
                        ),
                      ],
                    ),
                  ),
                  if (!widget.ekubRequest)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        AppKeys.viewLastPaid.tr(context).length > 14
                            ? '${AppKeys.viewLastPaid.tr(context).substring(0, 14)}…'
                            : AppKeys.viewLastPaid.tr(context),
                        style: AppTextStyles.poppins40010.copyWith(color: AppColors.primary),
                      ),
                    ),
                  if (widget.ekubRequest && !item.isGroup)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: GestureDetector(
                        onTap: () => showBeautifulInputDialog(context, item.id,
                            itemName: item.request?.itemName,
                            amount: item.request?.amount,
                            reason: item.request?.description,
                            requestId: item.request?.id),
                        child: Text(
                          'Request',
                          style: AppTextStyles.poppins40011.copyWith(color: AppColors.primary, decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No payments yet',
                style:
                    AppTextStyles.poppins40014.copyWith(color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  // ── Lotteries Tab ──────────────────────────────────────────────────────────

  Widget _buildLotteriesTab(int days, int hours, int minutes, int seconds) {
    final provider = context.watch<LotteryProvider>();
    final wheelNumbers = _wheelSlotNumbers(provider);
    final showingAllRounds = remainingTime > const Duration(days: 2) &&
        !_isRevealing &&
        !_holdingEarlyDrawReveal &&
        _currentWinnerNumber == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildCountdownRow(days, hours, minutes, seconds),
          const SizedBox(height: 24),

          if (remainingTime == Duration.zero &&
              _showNoWinnerState &&
              !_isRevealing &&
              _currentWinnerNumber == null)
            _buildNoWinnerState()
          else if (wheelNumbers.isEmpty && !_isRevealing)
            SizedBox(
              height: 320,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (provider.isLoading) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Loading lottery numbers...',
                        style: AppTextStyles.poppins40014
                            .copyWith(color: Colors.grey),
                      ),
                    ] else ...[
                      const Icon(Icons.hourglass_empty_rounded,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'No lottery numbers loaded',
                        style: AppTextStyles.poppins60016,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.error != null
                            ? 'Error: ${provider.error}'
                            : 'Waiting for data from server...',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.poppins40014
                            .copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<LotteryProvider>()
                              .fetchLotteries(widget.ekubId);
                          getEkubLotteries();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            Stack(
              clipBehavior: Clip.none,
              children: [
                LotteryWheel(
                  key: ValueKey(
                      'spin_${_spinGeneration}_${showingAllRounds ? 'all' : 'joined'}'),
                  lotteryNumbers: wheelNumbers.isNotEmpty
                      ? wheelNumbers
                      : (_currentWinnerNumber != null
                          ? [_currentWinnerNumber!]
                          : const <int>[1]),
                  // Keep results hidden during early-draw hold countdown.
                  isTimeUp:
                      !_holdingEarlyDrawReveal && _currentWinnerNumber != null,
                  winnerLotteryNumber:
                      _holdingEarlyDrawReveal ? null : _currentWinnerNumber,
                  hasNextWinner: _pendingWinnerNumbers.isNotEmpty,
                  onSpinComplete: _onWheelSpinComplete,
                ),
                if (_revealedCurrentDrawWinners.isNotEmpty)
                  Positioned(
                    top: 12,
                    right: 10,
                    child: _buildFloatingWinnerStack(),
                  ),
              ],
            ),

          const SizedBox(height: 24),
          if (!_shouldHideLotteryHistoryButton) ...[
            _buildLotteryHistoryButton(),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildNoWinnerState() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 320),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.vibrantGreen.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.vibrantGreen.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.vibrantGreen.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: AppColors.vibrantGreen,
              size: 40,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No winner for this round',
            textAlign: TextAlign.center,
            style: AppTextStyles.poppins70020.copyWith(color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
          Text(
            'The countdown has ended, but a winner has not been selected yet. Please check again shortly.',
            textAlign: TextAlign.center,
            style: AppTextStyles.poppins40014.copyWith(color: Colors.grey.shade600, height: 1.45),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () {
              _revealStarted = false;
              getElligbleUsers();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Check again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.vibrantGreen,
              side: BorderSide(color: AppColors.vibrantGreen.withOpacity(0.45)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              textStyle: AppTextStyles.poppins60014,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingWinnerStack() {
    final winners = _revealedCurrentDrawWinners.reversed.take(7).toList();
    return Container(
      constraints: BoxConstraints(maxWidth: 120.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Color(0xFFFFB300), size: 16),
              const SizedBox(width: 6),
              Text(
                AppKeys.winner.tr(context),
                style: AppTextStyles.poppins60013
                    .copyWith(color: const Color(0xFF1F2937)),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...winners.map(
            (winner) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${winner.lotteryNumber}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.poppins70020.copyWith(
                    color: AppColors.primary,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownRow(int days, int hours, int minutes, int seconds) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CountdownBox(value: days, label: 'Days'),
        _CountdownBox(value: hours, label: 'Hours'),
        _CountdownBox(value: minutes, label: 'Min'),
        _CountdownBox(value: seconds, label: 'Sec'),
      ],
    );
  }

  Widget _buildLotteryHistoryButton() {
    return Material(
      elevation: 3,
      shadowColor: AppColors.primary.withOpacity(0.3),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _isOpeningLotteryHistory ? null : _openLotteryHistory,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isOpeningLotteryHistory
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.history_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
              const SizedBox(width: 10),
              Text(
                AppKeys.lotteryHistory.tr(context),
                style: AppTextStyles.poppins60016.copyWith(color: Colors.white, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _CountdownBox extends StatelessWidget {
  final int value;
  final String label;
  const _CountdownBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF1DB954), Color(0xFF14833B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              value.toString().padLeft(2, '0'),
              style: AppTextStyles.poppins40022.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.poppins50011.copyWith(color: Color(0xFF888888))),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoPill(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: AppColors.vibrantGreen.withOpacity(0.12),
                  shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.vibrantGreen, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.poppins50011.copyWith(color: Color(0xFF888888))),
                Text(value,
                    style: AppTextStyles.poppins70014.copyWith(color: Color(0xFF1DB954))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _HeaderChipButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
        ),
        child: Text(
          label,
          style: AppTextStyles.poppins60012.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _PaymentSummarySheet extends StatelessWidget {
  final List<Payment> payments;
  final double total;
  final BuildContext context;
  const _PaymentSummarySheet(
      {required this.payments, required this.total, required this.context});

  @override
  Widget build(BuildContext outerCtx) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(AppKeys.payment.tr(context),
                    style: AppTextStyles.poppins70018),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: payments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = payments[i];
                    final sub = p.equbAmount * p.paidRound;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppKeys.lottery.tr(context)} ${p.lotteryNumber} (${p.paidRound} ${AppKeys.round.tr(context)})',
                            style: AppTextStyles.poppins50013,
                          ),
                          Text('$sub ETB',
                              style: AppTextStyles.poppins70014),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, -4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppKeys.totalAmount.tr(context),
                        style: AppTextStyles.poppins70016),
                    Text('$total ETB',
                        style: AppTextStyles.poppins70016.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StyledTabs extends StatelessWidget {
  final String text;
  final bool isSelected;
  const StyledTabs({super.key, required this.text, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 141.6,
        height: 34,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.vibrantGreen : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: AppTextStyles.poppins70014,
          ),
        ),
      ),
    );
  }
}
