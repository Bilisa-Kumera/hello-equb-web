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
import 'package:helloequb/screens/fortune_wheel_screen.dart';
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

  final Dio dio = Dio();
  final DataController dataController = DataController();
  final ApiService apiService = ApiService();

  List<Payment> _payments = [];
  List<Lottery> _lotteries = [];
  List<BankAccount> bankAccounts = [];
  BankAccount? selectedAccount;

  bool _isLoading = true;
  bool _hasNavigated = false;
  bool _showNoWinnerState = false;
  bool _isOpeningLotteryHistory = false;
  bool isRefreshed = false;
  bool isLoading = true;

  List<String> elligibleUsersList = [];
  List<String> elligibleUsersLotteryList = [];
  List<String> winnersList = [];
  List<String> currentWinnersList = [];
  List<String> currentWinnersIdList = [];

  List<dynamic> equbEligibleMembersSocket = [];
  List<dynamic> currentRoundWinnersSocket = [];
  List<dynamic> eligibleMembersSocket = [];

  List<String> lotteryNumbers = [];
  List<double> paidPerEachLottery = [];
  List<String> equbUserIds = [];

  String? ekubRound, totalPaid, equbers, userId;

  List<ListItems> listItemss = [];
  List<ListItem> listItems = [];

  DateTime? _cachedServerTime;
  Duration? _timeOffset;

  IO.Socket? socket;

  // ── Wheel spin state ───────────────────────────────────────────────────────
  late AnimationController _wheelController;
  late Animation<double> _wheelAnimation;
  bool _wheelSpinning = false;
  double _wheelStopAngle = 0;

  // ── Multi-winner queue ─────────────────────────────────────────────────────
  // Parsed int version of winnersList — populated after getElligbleUsers() returns.
  // The wheel spins one winner at a time; _pendingWinnerNumbers holds the rest.
  List<int> _pendingWinnerNumbers = [];
  int?
      _currentWinnerNumber; // null → wheel stays still; non-null → spin to this number

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<LotteryProvider>().fetchLotteries(widget.ekubId);
    });

    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _wheelAnimation = CurvedAnimation(
      parent: _wheelController,
      curve: Curves.decelerate,
    );
    _wheelController.addListener(() => setState(() {}));
    _wheelController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _wheelSpinning = false);
        // Show winner popup is handled inside LotteryWheelWidget / AnimatedWheelPainter
        // via onSpinComplete. If you use raw CustomPaint, trigger it here instead.
      }
    });

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    String updatedDateTime =
        '${widget.nextRoundDate.substring(0, 11)}${widget.nextRoundTime}:00Z';
    targetDateTime = DateTime.parse(updatedDateTime);

    initializePage();
    getListOfFinancialInfo();
    tokenUpdate();
    getMyEkubs(widget.ekubId);

    socket = IO.io(socketServer, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    getEkubLotteries();
    getEkubPayments();
    _startCountdown();
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Winner helpers ─────────────────────────────────────────────────────────

  /// Called when the countdown hits zero.
  /// Fetches eligible users, parses winnersList into ints, seeds the queue,
  /// and kicks off the first spin.
  Future<void> _onCountdownFinished() async {
    debugPrint('Countdown finished. Fetching eligible users and winners...');
    await getElligbleUsers(); // populates winnersList (List<String>)

    if (!mounted) {
      debugPrint('Widget not mounted after fetching winners.');
      return;
    }

    // Parse winnersList → List<int>, drop anything that isn't a valid number.
    final List<int> parsed =
        winnersList.map((s) => int.tryParse(s)).whereType<int>().toList();

    debugPrint('Parsed winner numbers: $parsed');

    if (parsed.isEmpty) {
      debugPrint('No winner found. Wheel will not spin.');
      debugPrint(
          'Showing no-winner state because parsed winners list is empty.');
      setState(() => _showNoWinnerState = true);
      return; // no winner yet — wheel stays still
    }

    setState(() {
      _showNoWinnerState = false;
      _pendingWinnerNumbers = List.from(parsed);
      _currentWinnerNumber = _pendingWinnerNumbers.removeAt(0);
    });

    debugPrint(
        'Set current winner number: $_currentWinnerNumber. Starting wheel spin.');
    // The wheel will react to _currentWinnerNumber becoming non-null
    // because LotteryWheelWidget / _spinToWinner checks it.
    _spinToWinner();
  }

  /// Called by the winner popup's Close button (via onSpinComplete) to spin
  /// the next winner when there are multiple winners in the queue.
  void _onWheelSpinComplete() {
    debugPrint('Wheel spin complete.');
    if (_pendingWinnerNumbers.isEmpty) {
      debugPrint('No more winners in queue.');
      return;
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) {
        debugPrint('Widget not mounted on spin complete.');
        return;
      }
      setState(() {
        _currentWinnerNumber = _pendingWinnerNumbers.removeAt(0);
      });
      debugPrint(
          'Next winner number: $_currentWinnerNumber. Spinning wheel again.');
      _spinToWinner();
    });
  }

  // ── Spin logic (uses _currentWinnerNumber) ─────────────────────────────────

  void _spinToWinner() {
    if (_wheelSpinning) {
      debugPrint('Wheel is already spinning.');
      return;
    }
    if (_currentWinnerNumber == null) {
      debugPrint('No winner number set. Wheel will not spin.');
      return;
    }

    final provider = context.read<LotteryProvider>();
    final segmentNumbers = provider.lotteries
        .map((e) => e.lotteryNumber)
        .whereType<int>()
        .toList();

    final int totalSegments =
        segmentNumbers.isNotEmpty ? segmentNumbers.length : 1;
    final double segAngle = 2 * pi / totalSegments;

    // Find the index of the winner in the wheel segment list.
    // Falls back to (winnerNumber - 1) if lotteryNumber matches positionally.
    int idx = segmentNumbers.indexOf(_currentWinnerNumber!);
    if (idx < 0) idx = (_currentWinnerNumber! - 1).clamp(0, totalSegments - 1);

    final double targetSegMid = idx * segAngle + segAngle / 2;
    // Rotate so the winner segment midpoint lands under the top pointer (−π/2).
    final double baseAngle = -pi / 2 - targetSegMid;
    // Add 8 full rotations for dramatic effect.
    final double totalAngle = (8 * 2 * pi) + baseAngle;

    _wheelStopAngle = totalAngle;

    debugPrint(
        'Spinning wheel to winner number $_currentWinnerNumber at index $idx, stop angle $_wheelStopAngle');
    setState(() => _wheelSpinning = true);
    _wheelController.forward(from: 0);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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

  // ── API calls ──────────────────────────────────────────────────────────────

  Future<void> getMyEkubs(String id) async {
    await Future.delayed(const Duration(seconds: 3));
    final Dio d = Dio();
    String token = await SecureStorageHelper.getAccessToken() ?? '';
    try {
      final res = await d.get('$ekubsUrl/$id',
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      if (res.statusCode == 200 || res.statusCode == 201) {
        String dt =
            '${res.data['data']['equb']['nextRoundDate'].substring(0, 11)}${res.data['data']['equb']['nextRoundTime']}:00';
        setState(() {
          targetDateTime = DateTime.parse('${dt}Z');
          isLoading = false;
        });
      }
    } catch (_) {}
  }

  Future<void> getElligbleUsers() async {
    String token = await SecureStorageHelper.getAccessToken() ?? '';
    try {
      final res = await dio.get(getEligibleUsers + widget.ekubId,
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.data['data'];
        final eligibleMembers = data['eligibleMembers'] as List<dynamic>;
        final currentWinners = data['currentRoundWinners'] as List<dynamic>;

        winnersList.clear();
        elligibleUsersList.clear();
        currentWinnersList.clear();
        currentWinnersIdList.clear();
        elligibleUsersLotteryList.clear();

        for (var m in eligibleMembers) {
          elligibleUsersLotteryList.add(m['lotteryNumber']);
        }
        for (var m in eligibleMembers)
          for (var u in m['users'] as List<dynamic>) {
            elligibleUsersList
                .add(_firstAndMiddleName(u['user']['fullName']?.toString()));
          }

        if (currentWinners.isEmpty) {
          debugPrint(
              'getElligbleUsers: currentRoundWinners is empty for equb ${widget.ekubId}.');
          debugPrint('Showing no-winner state after countdown finished.');
          if (mounted) setState(() => _showNoWinnerState = true);
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        int round = currentWinners[0]['winRound'];
        for (var w in currentWinners) {
          winnersList.add(w['lotteryNumber']);
        }
        for (var w in currentWinners)
          for (var u in w['users'] as List<dynamic>) {
            currentWinnersList
                .add(_firstAndMiddleName(u['user']['fullName']?.toString()));
            currentWinnersIdList.add(u['user']['id']);
          }

        elligibleUsersLotteryList =
            Set<String>.from(elligibleUsersLotteryList).toList();
        winnersList = Set<String>.from(winnersList).toList();
        debugPrint(
            'getElligbleUsers: winnersList=$winnersList, eligibleLotteryNumbers=$elligibleUsersLotteryList.');
        if (mounted) setState(() => _showNoWinnerState = winnersList.isEmpty);

        if (eligibleMembersSocket.isNotEmpty &&
            currentRoundWinnersSocket.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasNavigated) {
              _hasNavigated = true;
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => FortuneWheelScreen(
                          ekubId: widget.ekubId,
                          round: round,
                          ekubName: widget.ekubName,
                          ekubersNumber: widget.ekubersNumber,
                          ekubCycle: widget.ekubCycle,
                          nextRoundDate: widget.nextRoundDate,
                          nextRoundTime: widget.nextRoundTime,
                          ekubRequest: widget.ekubRequest,
                          serviceCharge: widget.serviceCharge,
                          nextRoundLotteryType: widget.nextRoundLotteryType,
                          elligibleMembersSocket: eligibleMembersSocket,
                          currentRoundWinnersSocket: currentRoundWinnersSocket,
                          equbElligibleMembersSocket: equbEligibleMembersSocket,
                          ekubAmount: widget.ekubAmount.toString())));
            }
          });
        }
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  Future<DateTime> fetchServerTime() async {
    final requestTime = DateTime.now();
    final res = await dio.get(getServerTimeUrl);
    if (res.statusCode == 200) {
      final responseTime = DateTime.now();
      final serverTime = DateTime.parse(res.data['date']);
      final rtt = responseTime.difference(requestTime).inMilliseconds / 2;
      _cachedServerTime = serverTime.add(Duration(milliseconds: rtt.toInt()));
      _timeOffset = _cachedServerTime!.difference(DateTime.now());
      return _cachedServerTime!;
    }
    throw Exception('Failed to fetch server time');
  }

  void _startCountdown() async {
    try {
      if (_cachedServerTime == null || _timeOffset == null)
        await fetchServerTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now().add(_timeOffset!);
        final newRemaining = targetDateTime.difference(now);
        setState(() {
          remainingTime =
              newRemaining.isNegative ? Duration.zero : newRemaining;
          if (newRemaining.isNegative) {
            timer.cancel();
            // ── Countdown just hit zero: fetch winners and spin ──
            _onCountdownFinished();
          }
        });
      });
    } catch (_) {}
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

    setState(() => _isOpeningLotteryHistory = true);
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

  void checkTargetDateTime() {
    socket!.connect();
    socket!.on('connect', (_) {});
    socket!.on('equb-lottery', (data) {
      try {
        if (data is Map<String, dynamic>) {
          String ekubId = data['equbId']?.toString() ?? '';
          if (ekubId == widget.ekubId) {
            String serverDate = data['date']?.toString() ?? '';
            DateTime serverDateTime = DateTime.parse(serverDate);
            targetDateTime = serverDateTime.add(Duration(
              days: data['remainingDays'] ?? 0,
              hours: data['remainingHours'] ?? 0,
              minutes: data['remainingMinutes'] ?? 0,
              seconds: data['remainingSeconds'] ?? 0,
            ));
            remainingTime = targetDateTime.difference(serverDateTime);
            setState(() {});
          }
        }
      } catch (_) {}
    });
    socket!.on('equb-eligible', (data) {
      if (data is Map<String, dynamic> &&
          data['status'] == 'success' &&
          mounted) {
        setState(() {
          eligibleMembersSocket =
              data['data']?['eligibleMembers'].toList() ?? '';
          currentRoundWinnersSocket =
              data['data']?['currentRoundWinners'].toList() ?? '';
          equbEligibleMembersSocket =
              data['data']?['equbEligibleMembers'].toList() ?? '';
        });
      }
    });
    socket!.on('disconnect', (_) {});
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
    checkTargetDateTime();

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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
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
        labelStyle: const TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14),
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
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
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
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
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
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(Payment item) {
    final bool isPaid = item.amountPaid == item.equbAmount &&
        item.paidRound >= int.parse(ekubRound ?? '0');

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => LotteryDetailBottomSheet(
            lottery: item.lotteryNumber, round: item.paidRound),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.earthySuccessGreen.withOpacity(0.12)
                      : AppColors.crimsonRed.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#${item.lotteryNumber}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isPaid
                          ? AppColors.earthySuccessGreen
                          : AppColors.crimsonRed,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D2D2D)),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13.sp,
                            color: Colors.grey[600]),
                        children: [
                          TextSpan(
                              text: numberFormat.format(
                                  item.amountPaid < 0 ? 0 : item.amountPaid),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D2D2D))),
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
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isPaid
                                ? AppColors.earthySuccessGreen
                                : AppColors.crimsonRed,
                          ),
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
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontFamily: 'Poppins'),
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
                        child: const Text(
                          'Request',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            decoration: TextDecoration.underline,
                          ),
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
                    TextStyle(color: Colors.grey[400], fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }

  // ── Lotteries Tab ──────────────────────────────────────────────────────────

  Widget _buildLotteriesTab(int days, int hours, int minutes, int seconds) {
    final provider = context.watch<LotteryProvider>();

    final wheelNumbers = provider.lotteries
        .map((e) => e.lotteryNumber)
        .whereType<int>()
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildCountdownRow(days, hours, minutes, seconds),
          const SizedBox(height: 24),

          // Loading state
          if (provider.isLoading)
            const SizedBox(
              height: 320,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Loading lottery numbers...',
                      style:
                          TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ),
            )

          // Empty state with helpful message
          else if (remainingTime == Duration.zero &&
              (_showNoWinnerState || wheelNumbers.isEmpty) &&
              _currentWinnerNumber == null)
            Builder(
              builder: (_) {
                debugPrint(
                    'Rendering no-winner state: timeUp=${remainingTime == Duration.zero}, showNoWinner=$_showNoWinnerState, wheelNumbers=${wheelNumbers.length}, currentWinner=$_currentWinnerNumber');
                return _buildNoWinnerState();
              },
            )
          else if (wheelNumbers.isEmpty)
            Container(
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_empty_rounded,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'No lottery numbers loaded',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error != null
                          ? 'Error: ${provider.error}'
                          : 'Waiting for data from server...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.grey, fontFamily: 'Poppins'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<LotteryProvider>()
                            .fetchLotteries(widget.ekubId);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )

          // Show the animated wheel when we have numbers
          else
            LotteryWheel(
              lotteryNumbers: wheelNumbers,
              isTimeUp: remainingTime == Duration.zero,
              winnerLotteryNumber: _currentWinnerNumber,
              hasNextWinner: _pendingWinnerNumbers.isNotEmpty,
              onSpinComplete: _onWheelSpinComplete,
            ),

          const SizedBox(height: 24),
          _buildLotteryHistoryButton(),
          const SizedBox(height: 24),
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
          const Text(
            'No winner for this round',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The countdown has ended, but a winner has not been selected yet. Please check again shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontFamily: 'Poppins',
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _onCountdownFinished,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Check again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.vibrantGreen,
              side: BorderSide(color: AppColors.vibrantGreen.withOpacity(0.45)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
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
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1),
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
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF888888))),
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
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1DB954))),
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
          style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600),
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
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
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
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                          Text('$sub ETB',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
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
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text('$total ETB',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
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
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.vibrantGreen,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
