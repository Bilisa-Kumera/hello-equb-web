// ignore_for_file: use_build_context_synchronously, deprecated_member_use, empty_catches

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:confetti/confetti.dart';
import 'package:helloequb/core/api_service_elper.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/models/ekub_category_model.dart';
import 'package:helloequb/models/financial_info.dart';
import 'package:helloequb/screens/complete_profile_screen.dart';
import 'package:helloequb/screens/fortune_wheel_screen.dart';
import 'package:helloequb/screens/guarantor_screen.dart';
import 'package:helloequb/screens/join_ekub_detail.dart';
import 'package:helloequb/screens/my_other_ekubs.dart';
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
import 'package:helloequb/screens/home_screen.dart';
import 'package:helloequb/screens/profile_screen.dart';
import 'package:helloequb/utils/carousel_card.dart';
import 'package:helloequb/utils/custom_bottom_nav.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../utils/secure_storage.dart';
import 'allequb_payment.dart';

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

  ApiResp({
    required this.status,
    required this.data,
  });

  factory ApiResp.fromJson(Map<String, dynamic> json) {
    return ApiResp(
      status: json['status'],
      data: Data.fromJson(json['data']),
    );
  }
}

class Data {
  final List<Lottery> lotteries;

  Data({
    required this.lotteries,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      lotteries: (json['lotteries'] as List<dynamic>)
          .map((lotteryJson) => Lottery.fromJson(lotteryJson))
          .toList(),
    );
  }
}

class Lottery {
  final List<User> users;

  Lottery({
    required this.users,
  });

  factory Lottery.fromJson(Map<String, dynamic> json) {
    return Lottery(
      users: (json['users'] as List<dynamic>)
          .map((userJson) => User.fromJson(userJson))
          .toList(),
    );
  }
}

class User {
  final String lotteryNumber;
  final String equberUserId;
  final String userId;
  final bool hasGuarantee;
  final double totalLotteryAmount;
  final double netLotteryAmount;
  final bool hasTakenEqub;
  final bool hasClaimed;
  final String userFullName;
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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
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
}

class UserStake {
  final String id;
  final int stake;
  final User user;

  UserStake({
    required this.id,
    required this.stake,
    required this.user,
  });

  factory UserStake.fromJson(Map<String, dynamic> json) {
    return UserStake(
      id: json['id'],
      stake: json['stake'],
      user: User.fromJson(json['user']),
    );
  }
}

class EligibleMember {
  final List<UserStake> users;

  EligibleMember({
    required this.users,
  });

  factory EligibleMember.fromJson(Map<String, dynamic> json) {
    var usersJson = json['users'] as List<dynamic>;
    List<UserStake> users = usersJson
        .map((userJson) => UserStake.fromJson(userJson as Map<String, dynamic>))
        .toList();

    return EligibleMember(
      users: users,
    );
  }
}

class CurrentWinner {
  final List<UserStake> users;

  CurrentWinner({
    required this.users,
  });

  factory CurrentWinner.fromJson(Map<String, dynamic> json) {
    var usersJson = json['users'] as List<dynamic>;
    List<UserStake> users = usersJson
        .map((userJson) => UserStake.fromJson(userJson as Map<String, dynamic>))
        .toList();

    return CurrentWinner(
      users: users,
    );
  }
}

class ResponseModel {
  final List<EligibleMember> eligibleMembers;
  final List<CurrentWinner> currentRoundWinners;

  ResponseModel({
    required this.eligibleMembers,
    required this.currentRoundWinners,
  });

  factory ResponseModel.fromJson(Map<String, dynamic> json) {
    var eligibleMembersJson = json['eligibleMembers'] as List<dynamic>;
    var currentRoundWinnersJson = json['currentRoundWinners'] as List<dynamic>;

    List<EligibleMember> eligibleMembers = eligibleMembersJson
        .map((memberJson) =>
            EligibleMember.fromJson(memberJson as Map<String, dynamic>))
        .toList();

    List<CurrentWinner> currentRoundWinners = currentRoundWinnersJson
        .map((winnerJson) =>
            CurrentWinner.fromJson(winnerJson as Map<String, dynamic>))
        .toList();

    return ResponseModel(
      eligibleMembers: eligibleMembers,
      currentRoundWinners: currentRoundWinners,
    );
  }
}

String _firstAndMiddleName(String? name) {
  final parts = (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  return parts.take(2).join(' ');
}

class PaymentResponse {
  final String status;
  final int equbRound;
  final List<Payment> payments;

  PaymentResponse({
    required this.status,
    required this.equbRound,
    required this.payments,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    final paymentsJson = (json['data']?['payments'] as List?) ?? const [];
    return PaymentResponse(
      status: json['status'],
      equbRound: json['data']['equbRound'],
      payments: List<Payment>.from(
        paymentsJson.map((payment) => Payment.fromJson(
              Map<String, dynamic>.from(payment as Map),
            )),
      ),
    );
  }
}

class Payment {
  final String name;
  final String id;
  final String lotteryNumber;
  final int totalPaid;
  final double amountPaid;
  final String equbersId;
  final double equbAmount;
  final bool paid;
  final int paidRound;
  final bool isGroup;
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

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      name: _firstAndMiddleName(json['name']?.toString()),
      id: json['id']?.toString() ?? '',
      // API may return lotteryNumber as int (e.g. 21). Keep it consistently as String.
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
}

class Request {
  final String id;
  final String itemName;
  final String description;
  final double amount;
  final String equberId;
  final String state;
  final DateTime createdAt;
  final DateTime updatedAt;

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

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
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
}

class MyEkubDetailScreen extends StatefulWidget {
  final String ekubName, ekubId;
  final int ekubAmount, ekubersNumber, ekubCycle;
  final String nextRoundDate;
  final String nextRoundTime;
  final bool ekubRequest;
  final String nextRoundLotteryType;
  final String serviceCharge;
  String? navigateFrom;
  final String ekubType;
  MyEkubDetailScreen(
      {super.key,
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
      required this.ekubType});

  @override
  State<MyEkubDetailScreen> createState() => _MyEkubDetailScreenState();
}

class _MyEkubDetailScreenState extends State<MyEkubDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTime targetDateTime = DateTime.now().add(const Duration(minutes: 1));
  Duration remainingTime = const Duration(minutes: 2);
  Timer? _timer;

  Future<void> tokenUpdate() async {
    TokenHelper.checkTokenExpiration(
      context: context,
      dio: dio,
      refreshTokenUrl: refreshTokenUrl,
      refreshToken: (await SecureStorageHelper.getRefreshToken()) ?? '',
    );
  }

  @override
  void initState() {
    // sendMessage("Hi Bekalu");
    super.initState();
    initializePage();
    getListOfFinancialInfo();
    tokenUpdate();
    getMyEkubs(widget.ekubId);
    socket = IO.io(socketServer, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    String updatedDateTime =
        '${widget.nextRoundDate.substring(0, 11)}${widget.nextRoundTime}:00Z';
    targetDateTime = DateTime.parse(updatedDateTime);
    getEkubLotteries();
    getEkubPayments();
    _startCountdown();
  }

  bool claimNow = false;

  final Dio dio = Dio();
  final DataController dataController = DataController();

  List<Payment> _payments = [];
  List<Lottery> _lotteries = [];

  bool _isLoading = true;
  List<String> elligibleUsersList = [];
  List<String> elligibleUsersLotteryList = [];
  List<String> winnersList = [];

  List<String> currentWinnersList = [];
  List<String> currentWinnersIdList = [];

  getMyEkubs(String id) async {
    await Future.delayed(const Duration(seconds: 3));

    final Dio dio = Dio();
    String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';

    try {
      final response = await dio.get(
        '$ekubsUrl/$id',
        options: Options(
          headers: {
            "Authorization": "Bearer $bearerToken",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        String updatedDateTime =
            '${response.data['data']['equb']['nextRoundDate'].substring(0, 11)}${response.data['data']['equb']['nextRoundTime']}:00';
        setState(() {
          targetDateTime = DateTime.parse("${updatedDateTime}Z");
          isLoading = false;
        });
      } else {
        return [];
      }
    } on DioError catch (error) {
      if (error.response != null &&
          error.response!.data['msg'] == 'Token is not valid') {
        // Handle token invalid error
      }
      return [];
    } catch (error) {
      return [];
    }
  }

  List<dynamic> equbEligibleMembersSocket = [];
  List<dynamic> currentRoundWinnersSocket = [];
  List<dynamic> eligibleMembersSocket = [];

  Future<void> getElligbleUsers() async {
    String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';
    try {
      final response = await dio.get(
        getEligibleUsers + widget.ekubId,
        options: Options(
          headers: {
            "Authorization": "Bearer $bearerToken",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Extract data from response
        final data = response.data['data'];
        final eligibleMembers = data['eligibleMembers'] as List<dynamic>;

        final currentWinners = data['currentRoundWinners'] as List<dynamic>;

        // Clear previous data
        winnersList.clear();
        elligibleUsersList.clear();
        currentWinnersList.clear();
        currentWinnersIdList.clear();
        elligibleUsersLotteryList.clear();

        // Populate eligibleUsersList
        for (var member in eligibleMembers) {
          elligibleUsersLotteryList.add(member['lotteryNumber']);
        }

        for (var member in eligibleMembers) {
          final users = member['users'] as List<dynamic>;
          for (var user in users) {
            elligibleUsersList
                .add(_firstAndMiddleName(user['user']['fullName']?.toString()));
          }
        }
        int round = 1;
        // Populate currentWinnersList
        round = currentWinners[0]['winRound'];

        for (var winner in currentWinners) {
          winnersList.add(winner['lotteryNumber']);
        }
        for (var winner in currentWinners) {
          final users = winner['users'] as List<dynamic>;
          for (var user in users) {
            currentWinnersList
                .add(_firstAndMiddleName(user['user']['fullName']?.toString()));
            currentWinnersIdList.add(user['user']['id']);
          }
        }

        Map<String, dynamic> lotteryDetailsMap = {
          'ekubWinnersLottery': winnersList,
          'elligibleUsersLottery': elligibleUsersLotteryList,
        };

        Set<String> uniqueUsersSet =
            Set<String>.from(elligibleUsersLotteryList);

        elligibleUsersLotteryList = uniqueUsersSet.toList();

        Set<String> uniqueWinnersListSet = Set<String>.from(winnersList);
        winnersList = uniqueWinnersListSet.toList();
        if (eligibleMembersSocket.isNotEmpty &&
            currentRoundWinnersSocket.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasNavigated) {
              _hasNavigated = true;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => FortuneWheelScreen(
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
                        // serviceCharge: widget.serviceCharge,
                        // ekubRequest: widget.ekubRequest,
                        // lotteryType: widget.nextRoundLotteryType,
                        // mapLotteryDetail: lotteryDetailsMap,
                        // ekubWinnersLottery: winnersList,
                        // elligibleUsersLottery: elligibleUsersLotteryList,
                        // elligibleUsers: elligibleUsersList,
                        // winnersEqub: currentWinnersIdList,
                        // ekubWinners: currentWinnersList,
                        ekubAmount: widget.ekubAmount.toString())),
              );
            }
          });
        } else {
          // CustomSnackBar.show(context, "Seems like there are no elligible Equbers for this round", Colors.deepOrangeAccent);
        }

        try {
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        } catch (error) {}
      } else {
        try {
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        } catch (error) {}
      }
    } on DioError catch (error) {
      if (error.response != null &&
          error.response!.data['msg'] == 'Token is not valid') {}
      try {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (error) {}
    } catch (error) {
      try {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (error) {}
    }
  }

  String? ekubRound, totalPaid, equbers;

  Future<void> getEkubLotteries() async {
    String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';
    try {
      final response = await dio.get(
        ekubLotteriesUrl + widget.ekubId,
        options: Options(
          headers: {
            "Authorization": "Bearer $bearerToken",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        List<dynamic> paymentsJson = response.data['data']['lotteries'];
        List<Lottery> lotteries =
            paymentsJson.map((json) => Lottery.fromJson(json)).toList();

        setState(() {
          _lotteries = lotteries;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } on DioError catch (error) {
      if (error.response != null &&
          error.response!.data['msg'] == 'Token is not valid') {}
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> lotteryNumbers = [];
  List<double> paidPerEachLottery = [];
  List<String> equbUserIds = [];

  Future<void> getEkubPayments() async {
    String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';
    try {
      final response = await dio.get(
        ekubPaymentsUrl + widget.ekubId,
        options: Options(
          headers: {
            "Authorization": "Bearer $bearerToken",
          },
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        ekubRound = response.data['data']['equbRound'].toString();
        totalPaid = response.data['data']['equbersPaid'].toString();
        equbers = response.data['data']['equbers'].toString();

        // Avoid duplicate entries if this method is called multiple times.
        lotteryNumbers.clear();
        paidPerEachLottery.clear();
        equbUserIds.clear();

        final paymentsJson = (response.data['data']['payments'] as List?) ?? [];
        final List<Payment> payments = paymentsJson
            .map((e) => Payment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        for (var lottery in payments) {
          lotteryNumbers.add(lottery.lotteryNumber);
          paidPerEachLottery.add(lottery.equbAmount);
          equbUserIds.add(lottery.equbersId);
        }

        setState(() {
          _payments = payments;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } on DioError catch (error) {
      if (error.response != null &&
          error.response!.data['msg'] == 'Token is not valid') {}
      if (error.response != null) {
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime? _cachedServerTime;
  Duration? _timeOffset;

  Future<DateTime> fetchServerTime() async {
    try {
      final requestTime = DateTime.now();
      final response = await dio.get(getServerTimeUrl);

      if (response.statusCode == 200) {
        final responseTime = DateTime.now();
        final serverTime = DateTime.parse(response.data['date']);
        final roundTripTime =
            responseTime.difference(requestTime).inMilliseconds / 2;

        // Cache the server time and calculate time offset
        _cachedServerTime =
            serverTime.add(Duration(milliseconds: roundTripTime.toInt()));
        _timeOffset = _cachedServerTime!.difference(DateTime.now());
        return _cachedServerTime!;
      } else {
        throw Exception('Failed to fetch server time: ${response.statusCode}');
      }
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  void _startCountdown() async {
    try {
      // Fetch server time only if it's not cached or outdated
      if (_cachedServerTime == null || _timeOffset == null) {
        await fetchServerTime();
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now().add(_timeOffset!); // Use cached time offset
        remainingTime = targetDateTime.difference(now);

        setState(() {
          if (remainingTime.isNegative) {
            remainingTime = Duration.zero;
            timer.cancel();
          }
        });
      });
    } catch (e) {}
  }

  void _handleTabSelection() {
    setState(() {});
  }

  List<BankAccount> bankAccounts = [];
  BankAccount? selectedAccount;

  final ApiService apiService = ApiService();

  Future<void> getListOfFinancialInfo() async {
    String accessToken = await SecureStorageHelper.getAccessToken() ?? '';
    final data =
        await apiService.readAll(addFinancialUrl, bearerToken: accessToken);

    if (data != null && data['data']?['bankAccounts']?.isNotEmpty) {
      final responseData = ResponseData.fromJson(data);

      setState(() {
        bankAccounts = responseData.bankAccounts;
      });
    } else {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
    _timer?.cancel();
  }

  IO.Socket? socket;

  void sendMessage(String message) {
    socket?.emit('message', message);
  }

  void checkTargetDateTime() {
    //  if(socket != null) {
    socket!.connect();
    socket!.onError(
      (data) {},
    );

    socket!.on('connect', (_) {});

    socket!.on('equb-lottery', (data) {
      try {
        if (data is Map<String, dynamic>) {
          String nextRoundDate = data['nextRoundDate']?.toString() ?? '';
          String serverDate = data['date']?.toString() ?? '';
          String ekubId = data['equbId']?.toString() ?? '';
          int remainingDays = data['remainingDays'] ?? 0;
          int remainingHours = data['remainingHours'] ?? 0;
          int remainingMinutes = data['remainingMinutes'] ?? 0;
          int remainingSeconds = data['remainingSeconds'] ?? 0;

          if (nextRoundDate.isNotEmpty && ekubId == widget.ekubId) {
            DateTime serverDateTime = DateTime.parse(serverDate);

            targetDateTime = serverDateTime.add(Duration(
              days: remainingDays,
              hours: remainingHours,
              minutes: remainingMinutes,
              seconds: remainingSeconds,
            ));

            remainingTime = targetDateTime.difference(serverDateTime);

            setState(() {});
          }
        } else {}
      } catch (e) {}
    });

    socket!.on('equb-eligible', (data) {
      if (data is Map<String, dynamic>) {
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              eligibleMembersSocket =
                  data['data']?['eligibleMembers'].toList() ?? '';
              currentRoundWinnersSocket =
                  data['data']?['currentRoundWinners'].toList() ?? '';
              equbEligibleMembersSocket =
                  data['data']?['equbEligibleMembers'].toList() ?? '';
            });
          }
        }
      } else {}
    });

    socket!.on('disconnect', (_) {});
  }

  bool _hasNavigated = false;

  void showWinningDialog(
      BuildContext context,
      String ekubId,
      String ekubAmount,
      String netLotteryAmount,
      String ekubName,
      String equberUserId,
      String serviceCharge) {
    ConfettiController _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return WinningDialog(
          ekubId: ekubId,
          ekubAmount: ekubAmount,
          netLotteryAmount: netLotteryAmount,
          ekubName: ekubName,
          equberUserId: equberUserId,
          serviceCharge: serviceCharge,
          bankAccounts: bankAccounts,
          selectedAccount: selectedAccount,
          onAccountSelected: (BankAccount? newAccount) {
            setState(() {
              selectedAccount = newAccount;
            });
          },
        );
      },
    );
  }

  Future<List<EqubCategorys>?> loadEkubCategories() async {
    List<dynamic>? jsonList =
        dataController.retrieveData<List<dynamic>>('ekubCategories');

    if (jsonList != null) {
      return jsonList
          .map((json) => EqubCategorys.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return null;
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            textScaleFactor: 1.0,
            "We're Sorry!",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.redAccent,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.redAccent,
                size: 50.0,
              ),
              const SizedBox(height: 20),
              Text(
                textScaleFactor: 1.0,
                message,
                style: const TextStyle(fontSize: 16.0),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(textScaleFactor: 1.0, "Loading..."),
            ),
          ],
        );
      },
    );
  }

  bool isRefreshed = false;
  bool isLoading = true;
  Future<void> initializePage() async {
    await Future.delayed(const Duration(seconds: 2));
    userId = await SecureStorageHelper.getUserId();

    if (widget.navigateFrom == "fortune" && !isRefreshed) {
      getMyEkubs(widget.ekubId);
      setState(() {
        isRefreshed = true;
      });
    }
  }

  List<ListItems> listItemss = [];
  List<ListItem> listItems = [];
  String? userId;

  Future<void> _handleRefresh() async {
    listItems = [];
    listItemss = [];
    if (remainingTime > const Duration(minutes: 2)) {
      getEkubPayments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("You can't refresh when less than 2 minutes remaining."),
        ),
      );
    }
    await Future.delayed(const Duration(seconds: 2));
  }

  void _showPaymentsBottomSheet(
    BuildContext context,
    List<Payment> payments,
  ) {
    final total = payments.fold<double>(
      0,
      (sum, item) => sum + (item.equbAmount * item.paidRound),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    AppKeys.payment.tr(context),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        final subtotal = payment.equbAmount * payment.paidRound;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${AppKeys.lottery.tr(context)} ${payment.lotteryNumber} (${payment.paidRound} ${AppKeys.round.tr(context)})",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "$subtotal ETB",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppKeys.totalAmount.tr(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$total ETB",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    checkTargetDateTime();

    final days = remainingTime.inDays;
    final hours = remainingTime.inHours % 24;
    final minutes = remainingTime.inMinutes % 60;
    final seconds = remainingTime.inSeconds % 60;
    bool timeIsUp = remainingTime.inDays == 0 &&
        remainingTime.inHours == 0 &&
        remainingTime.inMinutes == 0 &&
        remainingTime.inSeconds == 0;

    if (timeIsUp && !_hasNavigated) {
      sendMessage(widget.ekubId);
      if (eligibleMembersSocket.isNotEmpty &&
          currentRoundWinnersSocket.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasNavigated) {
            _hasNavigated = true;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => FortuneWheelScreen(
                      ekubId: widget.ekubId,
                      round: 1,
                      ekubName: widget.ekubName,
                      ekubersNumber: widget.ekubersNumber,
                      ekubCycle: widget.ekubCycle,
                      nextRoundDate: widget.nextRoundDate,
                      nextRoundTime: widget.nextRoundTime,
                      ekubRequest: widget.ekubRequest,
                      serviceCharge: widget.serviceCharge,
                      nextRoundLotteryType: widget.nextRoundLotteryType,
                      ekubAmount: widget.ekubAmount.toString(),
                      elligibleMembersSocket: eligibleMembersSocket,
                      currentRoundWinnersSocket: currentRoundWinnersSocket,
                      equbElligibleMembersSocket: equbEligibleMembersSocket)),
            );
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasNavigated) {
            _hasNavigated = true;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => FortuneWheelScreen(
                      ekubId: widget.ekubId,
                      round: 1,
                      ekubName: widget.ekubName,
                      ekubersNumber: widget.ekubersNumber,
                      ekubCycle: widget.ekubCycle,
                      nextRoundDate: widget.nextRoundDate,
                      nextRoundTime: widget.nextRoundTime,
                      ekubRequest: widget.ekubRequest,
                      serviceCharge: widget.serviceCharge,
                      nextRoundLotteryType: widget.nextRoundLotteryType,
                      ekubAmount: widget.ekubAmount.toString(),
                      elligibleMembersSocket: eligibleMembersSocket,
                      currentRoundWinnersSocket: currentRoundWinnersSocket,
                      equbElligibleMembersSocket: equbEligibleMembersSocket)),
            );
          }
        });
      }
    } else {}
    return Scaffold(
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // IMPORTANT

        child: Padding(
          padding: const EdgeInsets.only(top: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 10.0, top: 18, bottom: 18),
                    child: SizedBox(
                      width: 150.w,
                      child: Text(
                        widget.ekubName,
                        textScaleFactor: 1.0,
                        style: const TextStyle(
                          color: AppColors.neutralGray,
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.only(left: 18, right: 18),
                          side: const BorderSide(
                              color: AppColors.primary, width: 2.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: SizedBox(
                          width: 127.w,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppKeys.pendingPayments.tr(context),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => WaitingEkubsPayment(
                                        ekubId: widget.ekubId,
                                      )));
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (String value) {
                          if (value == 'report') {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => DownloadPdf(
                                          type: widget.ekubId,
                                          date:
                                              DateTime.now().toIso8601String(),
                                          image: '',
                                          result: 'result',
                                        )));
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            PopupMenuItem<String>(
                              value: 'report',
                              child: Text(
                                textScaleFactor: 1.0,
                                AppKeys.report.tr(context),
                              ),
                            ),
                          ];
                        },
                      )
                    ],
                  ),
                ],
              ),
              CarouselCard(
                  amount: numberFormat.format(widget.ekubAmount),
                  ekubName: widget.ekubName,
                  ekubersNumber: widget.ekubersNumber.toString(),
                  cycle: widget.ekubCycle.toString(),
                  total: _payments.fold<double>(
                    0,
                    (sum, item) => sum + (item.equbAmount * item.paidRound),
                  ),
                  buttonShow: false),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.transparent, // Hide the indicator
                tabs: [
                  StyledTabs(
                      text: AppKeys.payment.tr(context),
                      isSelected: _tabController.index == 0),
                  StyledTabs(
                      text: AppKeys.lotteries.tr(context),
                      isSelected: _tabController.index == 1),
                ],
              ),
              SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.55,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      onRefresh: _handleRefresh,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 18.0, bottom: 8, right: 24, left: 24),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    textScaleFactor: 1.0,
                                    AppKeys.nextRound.tr(context),
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.neutralGray),
                                  ),
                                  Text(
                                    textScaleFactor: 1.0,
                                    widget.ekubRequest
                                        ? '${widget.nextRoundLotteryType.toUpperCase()} / ${DateFormat('MMMM d').format(targetDateTime)}'
                                        : DateFormat('MMMM d')
                                            .format(targetDateTime)
                                            .toString(),
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.vibrantGreen),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(28.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    height: 49,
                                    width: 52,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: AppColors.pureBlack),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(5))),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          textScaleFactor: 1.0,
                                          '$days',
                                          style: const TextStyle(
                                              color: AppColors.vibrantGreen,
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        const Text(
                                          textScaleFactor: 1.0,
                                          'Days',
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.neutralGray),
                                        )
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 49,
                                    width: 52,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: AppColors.pureBlack),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(5))),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          textScaleFactor: 1.0,
                                          '$hours',
                                          style: const TextStyle(
                                              color: AppColors.vibrantGreen,
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        const Text(
                                          textScaleFactor: 1.0,
                                          'Hours',
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.neutralGray),
                                        )
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 49,
                                    width: 52,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: AppColors.pureBlack),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(5))),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          textScaleFactor: 1.0,
                                          '$minutes',
                                          style: const TextStyle(
                                              color: AppColors.vibrantGreen,
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        const Text(
                                          textScaleFactor: 1.0,
                                          'Min',
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.neutralGray),
                                        )
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 49,
                                    width: 52,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: AppColors.pureBlack),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(5))),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          textScaleFactor: 1.0,
                                          '$seconds',
                                          style: const TextStyle(
                                              color: AppColors.vibrantGreen,
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        const Text(
                                          textScaleFactor: 1.0,
                                          'Sec',
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.neutralGray),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 30,
                              width: 291,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5))),
                                  backgroundColor: AppColors.vibrantGreen,
                                ),
                                onPressed: () {
                                  _showPaymentArrangementDialog();
                                },
                                child: Text(
                                  textScaleFactor: 1.0,
                                  AppKeys.makePayment.tr(context),
                                  style: TextStyle(
                                      color: AppColors.pureWhite,
                                      fontFamily: 'Urbanist',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 34.0, right: 32, top: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      _showPaymentsBottomSheet(
                                          context, _payments);
                                    },
                                    child: Text(
                                      textScaleFactor: 1.0,
                                      AppKeys.viewPayments.tr(context),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    textScaleFactor: 1.0,
                                    '${AppKeys.round.tr(context)} $ekubRound',
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.neutralGray),
                                  )
                                ],
                              ),
                            ),
                            _isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(18.0),
                                    child: Center(
                                      child: SpinKitFadingCircle(
                                        color: AppColors.primary,
                                        size: 50.0,
                                      ),
                                    ),
                                  )
                                : _payments.isEmpty
                                    ? const Text(textScaleFactor: 1.0, "N/A")
                                    : Column(
                                        children: [
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: _payments.length,
                                            itemBuilder: (context, index) {
                                              final item = _payments[index];
                                              return InkWell(
                                                onTap: () {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return LotteryDetailBottomSheet(
                                                        lottery:
                                                            item.lotteryNumber,
                                                        round: item.paidRound,
                                                      );
                                                    },
                                                  );
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 28.0,
                                                          right: 24,
                                                          top: 2,
                                                          bottom: 10),
                                                  child: Container(
                                                    height: 79,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            const BorderRadius
                                                                .all(
                                                                Radius.circular(
                                                                    5)),
                                                        border: Border.all(
                                                            color: item
                                                                        .paid &&
                                                                    item.paidRound >=
                                                                        int.parse(ekubRound ??
                                                                            '0')
                                                                ? AppColors
                                                                    .earthySuccessGreen
                                                                : AppColors
                                                                    .crimsonRed,
                                                            width: 1)),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 12.0,
                                                              right: 12,
                                                              top: 18,
                                                              bottom: 10),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  textScaleFactor:
                                                                      1.0,
                                                                  '${item.name} (${item.lotteryNumber})',
                                                                  style: TextStyle(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      fontSize:
                                                                          14.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      color: const Color
                                                                          .fromRGBO(
                                                                          91,
                                                                          92,
                                                                          92,
                                                                          1)),
                                                                ),
                                                                Text(
                                                                  textScaleFactor:
                                                                      1.0,
                                                                  '${item.amountPaid < 0 ? 0.00 : numberFormat.format(item.amountPaid)}/${numberFormat.format(item.equbAmount)}',
                                                                  style: TextStyle(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      fontSize:
                                                                          14.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w400,
                                                                      color: const Color
                                                                          .fromRGBO(
                                                                          91,
                                                                          92,
                                                                          92,
                                                                          1)),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                100, // Fixed width for the right column
                                                            child: Center(
                                                              child: Column(
                                                                children: [
                                                                  Text(
                                                                    textScaleFactor:
                                                                        1.0,
                                                                    item.amountPaid == item.equbAmount &&
                                                                            item.paidRound >=
                                                                                int.parse(ekubRound ??
                                                                                    '0')
                                                                        ? AppKeys
                                                                            .paid
                                                                            .tr(
                                                                                context)
                                                                        : AppKeys
                                                                            .notPaid
                                                                            .tr(context),
                                                                    style: TextStyle(
                                                                        fontFamily:
                                                                            'Poppins',
                                                                        fontSize: 14
                                                                            .sp,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w700,
                                                                        color: const Color
                                                                            .fromRGBO(
                                                                            91,
                                                                            92,
                                                                            92,
                                                                            1)),
                                                                  ),
                                                                  widget
                                                                          .ekubRequest
                                                                      ? const SizedBox
                                                                          .shrink()
                                                                      : Padding(
                                                                          padding: const EdgeInsets
                                                                              .only(
                                                                              top: 4.0),
                                                                          child: Text(
                                                                              textScaleFactor: 1.0,
                                                                              AppKeys.viewLastPaid.tr(context).length > 14 ? '${AppKeys.viewLastPaid.tr(context).substring(0, 14)}...' : AppKeys.viewLastPaid.tr(context),
                                                                              style: const TextStyle(color: AppColors.primary, fontSize: 10)),
                                                                        ),
                                                                  const SizedBox(
                                                                    height: 3,
                                                                  ),
                                                                  widget.ekubRequest &&
                                                                          !item
                                                                              .isGroup
                                                                      ? InkWell(
                                                                          onTap: () => showBeautifulInputDialog(
                                                                              context,
                                                                              item.id,
                                                                              itemName: item.request?.itemName,
                                                                              amount: item.request?.amount,
                                                                              reason: item.request?.description,
                                                                              requestId: item.request?.id),
                                                                          child: const Text(
                                                                            textScaleFactor:
                                                                                1.0,
                                                                            'Request',
                                                                            style:
                                                                                TextStyle(decoration: TextDecoration.underline, color: AppColors.primary),
                                                                          ))
                                                                      : const SizedBox.shrink(),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          SizedBox(
                                            height: 3.h,
                                          ),
                                        ],
                                      ),
                            SizedBox(
                              height: 0.h,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      physics:
                          const AlwaysScrollableScrollPhysics(), // IMPORTANT

                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _lotteries.length,
                            itemBuilder: (context, lotteryIndex) {
                              final lottery = _lotteries[lotteryIndex];

                              return Column(
                                children: [
                                  for (var user in lottery.users)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 28.0,
                                          right: 24,
                                          top: 2,
                                          bottom: 10),
                                      child: Container(
                                        height: 69,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(5)),
                                            border: Border.all(
                                                color: user.hasTakenEqub
                                                    ? AppColors
                                                        .earthySuccessGreen
                                                    : AppColors.crimsonRed,
                                                width: 1)),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              left: 12.0,
                                              right: 12,
                                              top: 18,
                                              bottom: 10),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      textScaleFactor: 1.0,
                                                      widget.ekubRequest
                                                          ? user.lotteryNumber
                                                          : user.lotteryNumber,
                                                      style: const TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .neutralGray),
                                                    ),
                                                    Text(
                                                      textScaleFactor: 1.0,
                                                      user.hasTakenEqub
                                                          ? 'Taken'
                                                          : user.hasClaimed
                                                              ? 'Claimed'
                                                              : 'Not Claimed',
                                                      style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 13.sp,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: AppColors
                                                              .neutralGray),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                width: 100,
                                                child: Center(
                                                    child: user.userId == userId
                                                        ? SizedBox(
                                                            height: 26,
                                                            width: 190,
                                                            child:
                                                                OutlinedButton(
                                                              style:
                                                                  ButtonStyle(
                                                                backgroundColor: user
                                                                        .hasTakenEqub
                                                                    ? WidgetStateProperty.all(
                                                                        AppColors
                                                                            .primary)
                                                                    : user
                                                                            .hasClaimed
                                                                        ? WidgetStateProperty.all(AppColors
                                                                            .lightGrayBorder)
                                                                        : WidgetStateProperty.all(
                                                                            AppColors.boldSuccessGreen),
                                                              ),
                                                              onPressed:
                                                                  () async {
                                                                String
                                                                    accessToken =
                                                                    await SecureStorageHelper
                                                                            .getAccessToken() ??
                                                                        '';
                                                                ApiService
                                                                    apiService =
                                                                    ApiService();
                                                                final data = await apiService.readAll(
                                                                    getMyProfile,
                                                                    bearerToken:
                                                                        accessToken);
                                                                if (data !=
                                                                    null) {
                                                                  if (user.hasGuarantee &&
                                                                      !user
                                                                          .hasClaimed) {
                                                                    showWinningDialog(
                                                                        context,
                                                                        widget
                                                                            .ekubId,
                                                                        user.totalLotteryAmount
                                                                            .toString(),
                                                                        user.netLotteryAmount
                                                                            .toString(),
                                                                        widget
                                                                            .ekubName,
                                                                        user
                                                                            .equberUserId,
                                                                        widget
                                                                            .serviceCharge);
                                                                  } else if (user
                                                                      .hasClaimed) {
                                                                    // Handle already claimed case
                                                                  } else {
                                                                   
                                                                    final rawCompletion = data['data']
                                                                            ?[
                                                                            'user']
                                                                        ?[
                                                                        'profileCompletion'];

                                                                    final double completion = rawCompletion
                                                                            is num
                                                                        ? rawCompletion
                                                                            .toDouble()
                                                                        : double.tryParse(rawCompletion?.toString() ??
                                                                                '') ??
                                                                            0.0;

                                                                    final bool
                                                                        isProfileComplete =
                                                                        completion >=
                                                                            100;

                                                                    if (isProfileComplete) {
                                                                      Navigator
                                                                          .push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder: (context) =>
                                                                              GuarantorScreen(
                                                                            serviceCharge:
                                                                                widget.serviceCharge,
                                                                            ekubId:
                                                                                widget.ekubId,
                                                                            ekuberUserId:
                                                                                user.equberUserId,
                                                                            ekubAmount:
                                                                                widget.ekubAmount,
                                                                            ekubCycle:
                                                                                widget.ekubCycle,
                                                                            ekubName:
                                                                                widget.ekubName,
                                                                            ekubRequest:
                                                                                widget.ekubRequest,
                                                                            ekubersNumber:
                                                                                widget.ekubersNumber,
                                                                            nextRoundDate:
                                                                                widget.nextRoundDate,
                                                                            nextRoundLotteryType:
                                                                                widget.nextRoundLotteryType,
                                                                            nextRoundTime:
                                                                                widget.nextRoundTime,
                                                                          ),
                                                                        ),
                                                                      );
                                                                    } else {
                                                                      Navigator
                                                                          .push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder: (context) =>
                                                                              CompleteProfileScreen(
                                                                            serviceCharge:
                                                                                widget.serviceCharge,
                                                                            ekubId:
                                                                                widget.ekubId,
                                                                            ekubersUserId:
                                                                                user.equberUserId,
                                                                            ekubAmount:
                                                                                widget.ekubAmount,
                                                                            ekubCycle:
                                                                                widget.ekubCycle,
                                                                            ekubName:
                                                                                widget.ekubName,
                                                                            ekubRequest:
                                                                                widget.ekubRequest,
                                                                            ekubersNumber:
                                                                                widget.ekubersNumber,
                                                                            nextRoundDate:
                                                                                widget.nextRoundDate,
                                                                            nextRoundLotteryType:
                                                                                widget.nextRoundLotteryType,
                                                                            nextRoundTime:
                                                                                widget.nextRoundTime,
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                  }
                                                                } else {}
                                                              },
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        2.0),
                                                                child: Text(
                                                                  textScaleFactor:
                                                                      1.0,
                                                                  user
                                                                          .hasTakenEqub
                                                                      ? AppKeys
                                                                          .taken
                                                                          .tr(
                                                                              context)
                                                                      : user
                                                                              .hasClaimed
                                                                          ? AppKeys
                                                                              .claimed
                                                                              .tr(context)
                                                                          : user.hasGuarantee
                                                                              ? AppKeys.claim.tr(context)
                                                                              : AppKeys.claim.tr(context),
                                                                  style: TextStyle(
                                                                      color: AppColors
                                                                          .white,
                                                                      fontSize:
                                                                          13.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600),
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : Text(
                                                            textScaleFactor:
                                                                1.0,
                                                            '${AppKeys.round.tr(context)} ${user.round}',
                                                            style: const TextStyle(
                                                                fontFamily:
                                                                    'Poppins',
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Color
                                                                    .fromRGBO(
                                                                        91,
                                                                        92,
                                                                        92,
                                                                        1)),
                                                          )),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  // SizedBox(height: 120.h,),
                                ],
                              );
                            },
                          ),
                          SizedBox(
                            height: 0.h,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) async {
          switch (index) {
            case 0:
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()));

              break;
            case 1:
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ActiveEqubsScreen()));

              break;
            case 2:
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const PaymentList()));
              break;
            case 3:
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()));
              break;
            default:
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()));
              break;
          }
        },
      ),
    );
  }

  void _showPaymentArrangementDialog() {
    // Clear existing lists
    listItemss.clear();
    listItems.clear();

    // Use a Set to track unique lottery numbers
    final Set<String> uniqueLotteryNumbers = {};

    // Add items only if they are unique
    for (int i = 0; i < lotteryNumbers.length; i++) {
      if (uniqueLotteryNumbers.add(lotteryNumbers[i])) {
        // add() returns true if the item was added (wasn't already in the set)
        listItemss.add(ListItems(
          title: lotteryNumbers[i],
          subtitle: paidPerEachLottery[i]
              .toString(), // Use paidPerEachLottery instead of lotteryNumbers
          userIds: equbUserIds[i],
        ));
        listItems.add(ListItem(
          title: lotteryNumbers[i],
          subtitle: paidPerEachLottery[i].toString(),
        ));
      }
    }

    double expectedAmount = 0;
    for (var item in listItemss) {
      expectedAmount += double.parse(item.subtitle);
    }

    showDialog(
      context: context,
      builder: (context) => PaymentArragement(
        selectedJoinOption: listItems,
        selectedJoinOptions: listItemss,
        ekubAmount: widget.ekubAmount.toString(),
        ekubId: widget.ekubId,
        ekubName: widget.ekubName,
        ekubRound: ekubRound,
        round: ekubRound,
        expectedAmount: expectedAmount,
        type: 'payment',
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
      child: Container(
        width: 141.6,
        height: 30,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.vibrantGreen
              : const Color.fromARGB(255, 205, 205, 205),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(5),
            topRight: Radius.circular(5),
            bottomRight: Radius.circular(5),
            bottomLeft: Radius.circular(5),
          ),
        ),
        child: Center(
          child: isSelected
              ? Text(
                  textScaleFactor: 1.0,
                  text,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  textScaleFactor: 1.0,
                  text,
                  style: const TextStyle(
                    color: AppColors.vibrantGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
