// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/models/ekub_category_model.dart';
import 'package:ekubee/screens/home_screen.dart';
import 'package:ekubee/screens/my_ekub_detail_screen.dart';
import 'package:ekubee/screens/my_equb_screen.dart';
import 'package:ekubee/screens/my_other_ekubs.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/custom_snack_bar.dart';
import 'package:ekubee/utils/getx_storage_custom.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:rxdart/rxdart.dart';
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

  FortuneWheelScreen(
      {super.key,
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
      required this.equbElligibleMembersSocket});

  @override
  State<FortuneWheelScreen> createState() => _SpinWheelState();
}

class _SpinWheelState extends State<FortuneWheelScreen> {
  final selected = BehaviorSubject<int>();
  final confettiController =
      ConfettiController(duration: const Duration(seconds: 2));
  String winner = "";
  Timer? _timer;

  int winnerIndex = 0;
  List<String> shuffledItems = [];
  int currentWinnerIndex = 0;
  int countdown = 10;

  final Dio dio = Dio();
  final DataController dataController = DataController();
  bool _isLoading = true;

  List<String> elligibleUsersLotteryList = [];
  List<String> winnersList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.elligibleMembersSocket.isNotEmpty &&
          widget.currentRoundWinnersSocket.isNotEmpty) {
        setEligibleDataFromSocket();
      } else {
        getElligbleUsers();
      }
    });
  }

  void setEligibleDataFromSocket() {
    elligibleUsersLotteryList.clear();
    winnersList.clear();

    elligibleUsersLotteryList
        .addAll(widget.elligibleMembersSocket.map((e) => e['lotteryNumber']));

    winnersList.addAll(
        widget.currentRoundWinnersSocket.map((e) => e['lotteryNumber']));

    if (widget.currentRoundWinnersSocket.isNotEmpty) {
      round = widget.currentRoundWinnersSocket.first['winRound'];
    }

    if (elligibleUsersLotteryList.isEmpty && winnersList.isEmpty) {
      showErrorDialog('No eligible users or winners found.');
      return;
    }

    if (elligibleUsersLotteryList.isEmpty && winnersList.length == 1) {
      showWinnerDialog(winnersList[0]);
      return;
    }

    shuffleItems();
    startCountdown();

    setState(() {
      _isLoading = false;
    });
  }

  int round = 1;

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

        if (elligibleUsersLotteryList.isEmpty && winnersList.isEmpty) {
          showErrorDialog('No eligible users or winners found.');
          return;
        }

        if (elligibleUsersLotteryList.isEmpty && winnersList.length == 1) {
          showWinnerDialog(winnersList[0]);
          return;
        }

        shuffleItems();
        startCountdown();

        setState(() {
          _isLoading = false;
        });
      } else {
        showErrorDialog('Failed to retrieve data. Please try again.');
      }
    } catch (error) {
      showErrorDialog(
          'Seems like there are no eligible Equbers or no winners for this round.');
    }
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
              child: const Text(textScaleFactor: 1.0, "OK"),
            ),
          ],
        );
      },
    );
  }

  void shuffleItems() {
    // Combine eligible users and winners, ensuring no duplicates
    shuffledItems = elligibleUsersLotteryList.toSet().toList();
    shuffledItems.shuffle();
    for (var winner in winnersList) {
      if (!shuffledItems.contains(winner)) {
        shuffledItems.add(winner);
      }
    }
    winnerIndex = shuffledItems.indexOf(winnersList[currentWinnerIndex]);
  }

  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        if (mounted) {
          setState(() {
            countdown--;
          });
        }
      } else {
        _timer?.cancel();
        startSpinning();
      }
      if (countdown == 5) {
        widget.elligibleMembersSocket.isEmpty &&
                widget.currentRoundWinnersSocket.isEmpty
            ? getElligbleUsers()
            : null;
      }
    });
  }

  void startSpinning() {
    final int wheelSize = shuffledItems.length;
    const int spinsBeforeStopping = 4;
    final int selectedIndex = (wheelSize * spinsBeforeStopping) + winnerIndex;

    setState(() {
      selected.add(selectedIndex);
    });
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

  void showWinnerDialog(String winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
              textScaleFactor: 1.0,
              'Winner Announcement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, size: 50, color: AppColors.orange),
              const SizedBox(height: 16),
              Text(
                  textScaleFactor: 1.0,
                  'The winner is $winner!',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                  textScaleFactor: 1.0,
                  'Round: $round',
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(
                          textScaleFactor: 1.0,
                          AppKeys.information.tr(context)),
                      content: Text(
                        textScaleFactor: 1.0,
                        AppKeys.youCanClaim.tr(context),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text(
                              textScaleFactor: 1.0, AppKeys.ok.tr(context)),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                currentWinnerIndex++;
                if (currentWinnerIndex < winnersList.length) {
                  shuffleItems();
                  startCountdown();
                } else {
                  final ekubCategorys = await loadEkubCategories();

                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ActiveEqubsScreen()));
                }
              },
              style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(AppColors.primary)),
              child: Text(
                  textScaleFactor: 1.0,
                  currentWinnerIndex < winnersList.length - 1
                      ? 'Next Winner'
                      : 'My Equbs',
                  style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    selected.close();
    _timer?.cancel();
    confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const Center(
                  child: SpinKitFadingCircle(
                    color: AppColors.primary,
                    size: 50.0,
                  ),
                )
              else
                countdown > 0
                    ? Text(
                        textScaleFactor: 1.0,
                        '$countdown',
                        style: TextStyle(fontSize: 24.sp),
                      )
                    : Text(
                        textScaleFactor: 1.0,
                        'Spinning...',
                        style: TextStyle(fontSize: 24.sp),
                      ),
              const SizedBox(height: 20),
              if (!_isLoading && shuffledItems.isNotEmpty)
                SizedBox(
                  height: 350,
                  child: FortuneWheel(
                    selected: selected.stream,
                    animateFirst: false,
                    items: [
                      for (int i = 0; i < shuffledItems.length; i++)
                        FortuneItem(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 8),
                              child: Text(
                                textScaleFactor: 1.0,
                                shuffledItems[i],
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize:
                                        14.sp / (shuffledItems.length / 10),
                                    color: AppColors.white),
                              ),
                            ),
                          ),
                          style: FortuneItemStyle(
                            color: i % 2 == 0
                                ? AppColors.darkGreen
                                : AppColors.darkGreen, // Dark green-black
                            borderColor: AppColors.white,
                            borderWidth: 2.0,
                          ),
                        ),
                    ],
                    indicators: const <FortuneIndicator>[
                      FortuneIndicator(
                        alignment: Alignment.topCenter,
                        child: TriangleIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    styleStrategy: const UniformStyleStrategy(
                      color: AppColors.primary,
                      borderColor: AppColors.white,
                      borderWidth: 2.0,
                    ),
                    onAnimationEnd: () {
                      winner =
                          shuffledItems[selected.value % shuffledItems.length];
                      confettiController.play();
                      showWinnerDialog(winner);
                    },
                    physics: NoPanPhysics(),
                    duration: const Duration(seconds: 8),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
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
