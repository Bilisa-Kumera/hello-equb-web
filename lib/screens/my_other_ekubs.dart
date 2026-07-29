// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:dio/dio.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/style_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/models/ekub_category_model.dart';
import 'package:helloequb/models/financeandothermodel.dart' as f;
import 'package:helloequb/screens/my_ekub_detail_screen.dart';
import 'package:helloequb/screens/join_ekub_detail.dart';
import 'package:helloequb/screens/payment_arrangement_screen.dart';
import 'package:intl/intl.dart';
import 'package:helloequb/screens/saving_ekub_detail.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/custom_bottom_nav.dart';
import 'package:helloequb/utils/custom_snack_bar.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:helloequb/provider/joined_equbs_status_provider.dart';
import 'package:helloequb/provider/equb_type_provider.dart' as type_provider;
import 'package:helloequb/provider/equb_category_provider.dart';
import 'package:helloequb/provider/getmyequb_provider.dart';
import 'package:helloequb/screens/my_equb_screen.dart';

import 'package:helloequb/utils/getx_storage_custom.dart' show DataController;
import 'package:helloequb/utils/lang_constants.dart' show AppKeys;
import 'package:helloequb/utils/equb_type_localization.dart';
import 'package:helloequb/utils/equb_date_utils.dart';
import 'package:helloequb/utils/main_nav_helper.dart';

import '../utils/secure_storage.dart';
import 'pending_equbs_screen.dart';

class ActiveEqubsScreen extends StatefulWidget {
  final bool embedInShell;

  const ActiveEqubsScreen({super.key, this.embedInShell = false});

  @override
  _ActiveEqubsScreenState createState() => _ActiveEqubsScreenState();
}

class _ActiveEqubsScreenState extends State<ActiveEqubsScreen>
    with TickerProviderStateMixin {
  final DataController dataController = DataController();
  late TabController _mainTabController;
  TabController? _categoryTabController;
  int selectedCategoryIndex = 0;
  bool _hasFetchedInitial = false;
  bool _isBootstrapping = false;
  bool _isOpeningQuickPayment = false;

  @override
  void initState() {
    super.initState();
    stopProgressAfterDelay();
    loadEkubCategories();
    _mainTabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrapScreen();
      if (widget.embedInShell) {
        context.read<JoinedEqubsStatusProvider>().refresh();
      }
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _categoryTabController?.dispose();
    super.dispose();
  }

  int totalEqubs = 0;

  Future<List<PendingEqub>> getMyEkubs({
    required String type,
    required String category,
    String? url,
  }) async {
    final String cacheKey = 'type:$type:category:$category';
    final cachedData = EqubCache.get(cacheKey);

    if (cachedData != null) {
      _fetchAndUpdateCache(type, category, cacheKey, urls: url);
      return cachedData;
    }

    return await _fetchAndUpdateCache(type, category, cacheKey, urls: url);
  }

  f.FinanceAndOtherResponse? responseData;

  Future<f.FinanceAndOtherResponse> _fetchFinanceAndOtherData(
      String type, String category, String urls) async {
    try {
      final Dio dio = Dio();
      String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';
      final String userId = await SecureStorageHelper.getUserId() ??
          await SecureStorageHelper.getUserId() ??
          '';

      final String url =
          "$financeAndOtherEqubsUrl$userId?equbTypeId=$type&equbCategoryId=$category";

      final response = await dio.get(
        url,
        options: Options(
          headers: {"Authorization": "Bearer $bearerToken"},
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        responseData = f.FinanceAndOtherResponse.fromJson(response.data);

        return responseData!;
      } else {
        return responseData!;
      }
    } on DioError {
      return responseData!;
    } catch (error) {
      return responseData!;
    }
  }

  Future<List<PendingEqub>> _fetchAndUpdateCache(
      String type, String category, String cacheKey,
      {String? urls}) async {
    try {
      final Dio dio = Dio();
      String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';
      final String userId = await SecureStorageHelper.getUserId() ?? '';

      final String url = urls == null
          ? '$ekubsUrl?_page&_limit&equbType=$type&equbCategory=$category&user=$userId&status=joined'
          : "$financeAndOtherEqubsUrl$userId?equbTypeId=$type&equbCategoryId=$category";

      final response = await dio.get(
        url,
        options: Options(
          headers: {
            "Authorization": "Bearer $bearerToken",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (urls == null) {}
        List<dynamic> pendingEqubsJson = response.data['data']['equbs'];
        totalEqubs = pendingEqubsJson.length;
        List<PendingEqub> freshData = pendingEqubsJson
            .map((json) => PendingEqub.fromJson(
                  json as Map<String, dynamic>,
                  currentUserId: userId,
                ))
            .toList();
        PendingEqub.sortByLatestJoined(freshData);

        EqubCache.set(cacheKey, freshData);
        totalEqubs = freshData.length;

        return freshData;
      } else {
        return [];
      }
    } on DioError catch (error) {
      if (error.response != null &&
          error.response!.data['msg'] == 'Token is not valid') {}
      return [];
    } catch (error) {
      return [];
    }
  }

  bool progress = true;
  void stopProgressAfterDelay() {
    Future.delayed(const Duration(seconds: 7), () {
      // setState(() {
        progress = false;
      // });
    });
  }

  int ekubTypeIndex = 0;
  int selectedEqubTypeIndex = 0;

  List<EqubCategory> _filteredCategories(
      BuildContext context, List<EqubCategory> categories) {
    return [
      EqubCategory(
        id: '',
        name: AppKeys.all.tr(context),
        createdAt: '',
        description: '',
        hasReason: false,
        needsRequest: false,
        state: '',
        updatedAt: '',
      ),
      ...categories,
    ];
  }

  Future<void> _bootstrapScreen() async {
    if (_isBootstrapping || !mounted) return;
    _isBootstrapping = true;

    try {
      final typeProvider = context.read<type_provider.EqubTypeProvider>();
      final categoryProvider = context.read<EqubCategoryProvider>();

      final bootstrapTasks = <Future<void>>[];
      if (typeProvider.equbTypes == null || typeProvider.equbTypes!.isEmpty) {
        bootstrapTasks.add(typeProvider.fetchEqubTypes());
      }
      if (categoryProvider.equbCategories == null ||
          categoryProvider.equbCategories!.isEmpty) {
        final categoriesFuture = categoryProvider.fetchEqubCategories();
        if (categoriesFuture != null) {
          bootstrapTasks.add(categoriesFuture);
        }
      }

      if (bootstrapTasks.isNotEmpty) {
        await Future.wait(bootstrapTasks);
      }

      if (!mounted) return;
      await _fetchInitialEqubsIfNeeded();
    } finally {
      _isBootstrapping = false;
    }
  }

  Future<void> _fetchInitialEqubsIfNeeded() async {
    if (!mounted || _hasFetchedInitial) return;

    final typeProvider = context.read<type_provider.EqubTypeProvider>();
    final categoryProvider = context.read<EqubCategoryProvider>();

    final types =
        typeProvider.equbTypes?.where((t) => t.id != null).toList() ?? [];
    if (types.isEmpty) return;

    final categories = categoryProvider.equbCategories
            ?.where((c) => c.id != null)
            .toList() ??
        [];
    final filteredCategories = _filteredCategories(context, categories);

    _hasFetchedInitial = true;
    await _fetchEqubsForCurrentSelection(
      context,
      types,
      filteredCategories,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchEqubsForCurrentSelection(
      BuildContext context, List types, List filteredCategories) async {
    final getMyEqubProvider =
        Provider.of<GetMyEqubProvider>(context, listen: false);
    final userId = await SecureStorageHelper.getUserId() ?? '';
    final typeId = types[selectedEqubTypeIndex].id ?? '';

    // Ensure selectedCategoryIndex is valid
    final safeCategoryIndex = selectedCategoryIndex < filteredCategories.length
        ? selectedCategoryIndex
        : 0;
    final catId = filteredCategories[safeCategoryIndex].id ?? '';

    if (typeId.isNotEmpty && userId.isNotEmpty) {
      await getMyEqubProvider.fetchEqubs(
        equbTypeId: typeId,
        equbCategoryId: catId,
        userId: userId,
      );

      if (!mounted || !widget.embedInShell) return;

      final active = getMyEqubProvider.equbs
          .where((equb) =>
              equb.status.trim().toLowerCase() != AppKeys.completed)
          .toList();
      context.read<JoinedEqubsStatusProvider>().syncFromPendingEqubs(active);

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffold = Scaffold(
        extendBody: !widget.embedInShell,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(140.h),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.forestGreenPrimary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.black26,
              //     blurRadius: 16,
              //     offset: Offset(0, 4),
              //   ),
              // ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppKeys.myEkub.tr(context),
                      style: AppTextStyles.appBarTitle.copyWith(
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          AppKeys.trackAll.tr(context),
                          style: AppTextStyles.appBarSubtitle.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(width: 20.h),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const WaitingEkubs()),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.pending_actions,
                                    size: 20.r, color: AppColors.white),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(AppKeys.pendingEkubs.tr(context),
                                    maxLines: 1,
                                    style: AppTextStyles.listTitle.copyWith(
                                      color: AppColors.white,
                                      letterSpacing: 0.3,
                                      overflow: TextOverflow.ellipsis
                                    ),
                                    overflow: TextOverflow.clip,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: _buildTabContent(0, url: null),
        bottomNavigationBar: widget.embedInShell
            ? null
            : Consumer<JoinedEqubsStatusProvider>(
                builder: (context, joinStatus, _) {
                  const currentIndex = 0;
                  return CustomBottomNavigationBar(
                    showMyEqubTab: joinStatus.hasJoinedEqubs,
                    currentIndex: currentIndex,
                    onTap: (index) => onMainBottomNavTap(
                      context,
                      tappedIndex: index,
                      currentIndex: currentIndex,
                    ),
                  );
                },
              ),
      );

    if (widget.embedInShell) {
      return scaffold;
    }

    return WillPopScope(
      onWillPop: () async {
        await navigateToMainShell(
          context,
          initialIndex: newEqubTabIndex(context),
        );
        return false;
      },
      child: scaffold,
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

  String _formatEqubDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date.toLocal());
  }

  DateTime? _resolveEqubEndDate(PendingEqub equb) {
    if (equb.endDate != null) return equb.endDate;

    final types = context.read<type_provider.EqubTypeProvider>().equbTypes;
    type_provider.EqubType? providerType;
    if (types != null) {
      for (final t in types) {
        if (t.id == equb.equbTypeId) {
          providerType = t;
          break;
        }
      }
    }

    return calculateEqubEndDate(
      startDate: equb.startDate,
      numberOfRounds: equb.numberOfEqubers,
      intervalDays: equb.equbType?.interval ?? providerType?.interval,
      typeName: equb.equbType?.name ?? providerType?.name,
    );
  }

  void _openEqubDetail(PendingEqub equb) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyEkubDetailScreen(
          ekubType: equb.equbCategory?.name ?? 'Finance',
          serviceCharge: equb.serviceCharge.toString(),
          nextRoundTime: equb.nextRoundTime ?? '',
          ekubCycle: equb.numberOfEqubers,
          nextRoundDate: equb.nextRoundDate ?? '',
          ekubAmount: equb.equbAmount * equb.numberOfEqubers,
          ekubName: equb.name,
          ekubersNumber: equb.equbers?.length ?? 0,
          nextRoundLotteryType: equb.nextRoundLotteryType,
          ekubId: equb.id,
          ekubRequest: equb.equbCategory?.needsRequest ?? false,
        ),
      ),
    );
  }

  Future<void> _openQuickPayment(PendingEqub equb) async {
    if (_isOpeningQuickPayment) return;
    setState(() => _isOpeningQuickPayment = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: SpinKitFadingCircle(color: AppColors.primary, size: 40),
      ),
    );

    try {
      final token = await SecureStorageHelper.getAccessToken() ?? '';
      final res = await Dio().get(
        ekubPaymentsUrl + equb.id,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close loader

      if (res.statusCode != 200 && res.statusCode != 201) {
        setState(() => _isOpeningQuickPayment = false);
        CustomSnackBar.show(
          context,
          AppKeys.noData.tr(context),
          Colors.red,
        );
        return;
      }

      final ekubRound = res.data['data']['equbRound']?.toString() ??
          equb.nextRound.toString();
      final payments = ((res.data['data']['payments'] as List?) ?? [])
          .map((e) => Payment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final listItemss = <ListItems>[];
      final listItems = <ListItem>[];
      final seen = <String>{};
      for (final p in payments) {
        if (!seen.add(p.lotteryNumber)) continue;
        listItemss.add(ListItems(
          title: p.lotteryNumber,
          subtitle: p.equbAmount.toString(),
          userIds: p.equbersId,
        ));
        listItems.add(ListItem(
          title: p.lotteryNumber,
          subtitle: p.equbAmount.toString(),
        ));
      }

      if (listItems.isEmpty) {
        setState(() => _isOpeningQuickPayment = false);
        CustomSnackBar.show(
          context,
          AppKeys.noData.tr(context),
          Colors.red,
        );
        return;
      }

      final expected =
          listItemss.fold<double>(0, (s, e) => s + double.parse(e.subtitle));

      if (!mounted) return;
      setState(() => _isOpeningQuickPayment = false);
      showDialog(
        context: context,
        builder: (_) => PaymentArragement(
          selectedJoinOption: listItems,
          selectedJoinOptions: listItemss,
          ekubAmount: equb.equbAmount.toString(),
          ekubId: equb.id,
          ekubName: equb.name,
          ekubRound: ekubRound,
          round: ekubRound,
          expectedAmount: expected,
          type: 'payment',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close loader
      setState(() => _isOpeningQuickPayment = false);
      CustomSnackBar.show(
        context,
        AppKeys.enableInternet.tr(context),
        Colors.red,
      );
    }
  }

  Widget _buildEqubInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? secondaryValue,
  }) {
    final secondary = secondaryValue?.trim();
    final hasSecondary = secondary != null && secondary.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: AppColors.primary),
          SizedBox(width: 6.w),
          if (hasSecondary) ...[
            Expanded(
              flex: 2,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionMuted
                    .copyWith(color: Colors.grey.shade700),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    style: AppTextStyles.labelSmall,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.captionMuted.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              child: Row(
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionMuted
                        .copyWith(color: Colors.grey.shade700),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEqubStatusBadge(String status, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: const Color(0xFFC9A227),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        status.toLowerCase().tr(context),
        style: AppTextStyles.badge.copyWith(
          color: Colors.white,
          fontSize: 9.sp,
        ),
      ),
    );
  }

  Widget _buildJoinedEqubCard(PendingEqub equb, int idx) {
    final equbName =
        (equb.name.trim().isNotEmpty) ? equb.name.trim() : (equb.equbType?.name ?? 'Equb');
    final amountText =
        '${numberFormat.format(equb.equbAmount)} ${AppKeys.currencyBirr.tr(context)}';
    final totalAmount =
        numberFormat.format(equb.equbAmount * equb.numberOfEqubers);
    final startParts = resolveEthiopianGregorianParts(
      ethiopianDate: equb.ethiopianStartDate,
      gregorianDate: equb.startDate,
      formatGregorian: _formatEqubDate,
    );
    final endParts = resolveEthiopianGregorianParts(
      ethiopianDate: equb.ethiopianEndDate,
      gregorianDate: _resolveEqubEndDate(equb),
      formatGregorian: _formatEqubDate,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + idx * 50),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16.h * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          equbName,
                          style: AppTextStyles.poppins60014,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          amountText,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                _buildEqubStatusBadge(equb.status, context),
              ],
            ),
            SizedBox(height: 8.h),
            _buildEqubInfoRow(
              icon: Icons.account_balance_wallet_outlined,
              label: AppKeys.totalAmount.tr(context),
              value: '$totalAmount ${AppKeys.currencyBirr.tr(context)}',
            ),
            _buildEqubInfoRow(
              icon: Icons.calendar_today_outlined,
              label: AppKeys.expectedStartDate.tr(context),
              value: startParts.ethiopian,
              secondaryValue:
                  startParts.gregorian == '-' ? null : startParts.gregorian,
            ),
            _buildEqubInfoRow(
              icon: Icons.event_outlined,
              label: AppKeys.expectedEndDate.tr(context),
              value: endParts.ethiopian,
              secondaryValue:
                  endParts.gregorian == '-' ? null : endParts.gregorian,
            ),
            _buildEqubInfoRow(
              icon: Icons.autorenew_rounded,
              label: AppKeys.round.tr(context),
              value: '${equb.currentRound}/${equb.numberOfEqubers}',
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: OutlinedButton(
                    onPressed: _isOpeningQuickPayment
                        ? null
                        : () => _openQuickPayment(equb),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      backgroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    child: Text(
                      AppKeys.quickPayment.tr(context),
                      style: AppTextStyles.button
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  flex: 4,
                  child: ElevatedButton(
                    onPressed: () => _openEqubDetail(equb),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    child: Text(
                      AppKeys.lblContinue.tr(context),
                      style: AppTextStyles.button
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(int index, {String? url}) {
    return Consumer2<type_provider.EqubTypeProvider, EqubCategoryProvider>(
      builder: (context, typeProvider, categoryProvider, _) {
          final types =
              typeProvider.equbTypes?.where((t) => t.id != null).toList() ?? [];
          final categories = categoryProvider.equbCategories
                  ?.where((c) => c.id != null)
                  .toList() ??
              [];

          final filteredCategories = _filteredCategories(context, categories);

          if (types.isEmpty) {
            if (!_isBootstrapping) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _bootstrapScreen();
              });
            }
            return Center(
              child: LoadingAnimationWidget.threeRotatingDots(
                color: AppColors.vibrantGreen,
                size: 30,
              ),
            );
          }

          if (selectedEqubTypeIndex >= types.length) {
            selectedEqubTypeIndex = 0;
          }

          if (selectedCategoryIndex >= filteredCategories.length) {
            selectedCategoryIndex = 0;
          }

          if (!_hasFetchedInitial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchInitialEqubsIfNeeded();
            });
          }

          if (filteredCategories.isEmpty) {
            return Center(child: Text(AppKeys.noCategories.tr(context)));
          }

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Container(
                  height: 40.h,
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.12),
                        blurRadius: 20.r,
                         spreadRadius: 10.r
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      key: ValueKey(
                          'category_dropdown_${filteredCategories.length}_$selectedCategoryIndex'),
                      value: selectedCategoryIndex < filteredCategories.length
                          ? selectedCategoryIndex
                          : 0,
                      isExpanded: true,
                      isDense: true,
                      borderRadius: BorderRadius.circular(12.r),
                      icon: Icon(Icons.keyboard_arrow_down, size: 22.sp),
                      style: AppTextStyles.tabLabel.copyWith(
                        color: AppColors.black,
                      ),
                      items: List.generate(
                        filteredCategories.length,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: Text(
                            filteredCategories[index].name ?? 'Unknown',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ),
                      onChanged: (index) {
                        if (index == null) return;
                        setState(() => selectedCategoryIndex = index);
                        _fetchEqubsForCurrentSelection(
                            context, types, filteredCategories);
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 40.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: types.length,
                  separatorBuilder: (_, __) => SizedBox(width: 20.w),
                  itemBuilder: (context, idx) {
                    final type = types[idx];
                    final isSelected = idx == selectedEqubTypeIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedEqubTypeIndex = idx;
                          selectedCategoryIndex = 0;
                        });
                        _fetchEqubsForCurrentSelection(
                            context, types, filteredCategories);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                            horizontal: 22.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withOpacity(isSelected ? 0.15 : 0.08),
                              blurRadius: isSelected ? 12.r : 8.r,
                              offset: Offset(0, isSelected ? 4.h : 2.h),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            translateEqubTypeName(
                              context,
                              type.name,
                              interval: type.interval,
                            ),
                            style: (isSelected
                                    ? AppTextStyles.chipSelected
                                    : AppTextStyles.chip)
                                .copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 12.h),

              // Equb list
              Expanded(
                child: Consumer<GetMyEqubProvider>(
                  builder: (context, equbProvider, _) {
                    if (equbProvider.isLoading && equbProvider.equbs.isEmpty) {
                      return Center(
                        child: LoadingAnimationWidget.threeRotatingDots(
                          color: AppColors.vibrantGreen,
                          size: 30.sp,
                        ),
                      );
                    } else if (equbProvider.errorMessage != null) {
                      return Center(
                          child: Text(AppKeys.errorTryAgain.tr(context)));
                    }

                    var visibleEqubs = equbProvider.equbs
                        .where((e) =>
                            e.status.trim().toLowerCase() != AppKeys.completed)
                        .toList();
                    PendingEqub.sortByLatestJoined(visibleEqubs);

                    if (visibleEqubs.isEmpty) {
                      return Center(child: Text(AppKeys.noEkubs.tr(context)));
                    }

                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 16.h),
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemCount: visibleEqubs.length,
                      itemBuilder: (context, idx) {
                        return _buildJoinedEqubCard(visibleEqubs[idx], idx);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
  }

  final Dio dio = Dio();

  Future<DateTime> fetchServerTime() async {
    try {
      final response = await dio.get(getServerTimeUrl);
      if (response.statusCode == 200) {
        return DateTime.parse(response.data['date']);
      } else {
        throw Exception(AppKeys.failedToFetchTime.tr(context));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<f.UserData>> mergeJoinedEqubs(
      List<f.UserData> activeEqubs) async {
    List<f.UserData> mergedList = [];

    for (var item in activeEqubs) {
      if (item.joinedEqubs != null) {
        for (var equb in item.joinedEqubs!) {
          final status = (equb.status ?? '').toString().trim().toLowerCase();
          // Compare using the backend status value, not the localized label.
          if (status == AppKeys.completed) continue;

          mergedList.add(f.UserData(
            id: item.id,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            email: item.email,
            fullName: item.fullName,
            isVerified: item.isVerified,
            phoneNumber: item.phoneNumber,
            avatar: item.avatar,
            // Keep only the equb for this row; the UI below expects a single item.
            joinedEqubs: [equb],
            profileCompletion: item.profileCompletion,
            state: item.state,
            firstName: item.firstName,
            lastName: item.lastName,
            middleName: item.middleName,
          ));
        }
      }
    }

    return mergedList;
  }

  String getImagePath(String equbCategory, bool left) {
    switch (equbCategory) {
      case 'Finance':
        return left ? 'assets/birr.png' : 'assets/birr2.png';
      case 'Savings':
        return left ? 'assets/birr.png' : 'assets/birr2.png';
      case 'Car':
        return left ? 'assets/car4.png' : 'assets/car2.png';
      case 'House':
        return left ? 'assets/home1.png' : 'assets/home2.png';
      case 'Travel':
        return left ? 'assets/lefttravel.png' : 'assets/righttravel.png';
      case 'Special Finance':
        return left ? 'assets/birr.png' : 'assets/special1.png';
      default:
        return left
            ? 'assets/birr.png'
            : 'assets/birr2.png'; // Default image for unknown categories
    }
  }

  Widget _buildCardList(String type, String category, {String? url}) {
    final safeType = dataController.retrieveData(type) ?? '';
    final safeCategory = dataController.retrieveData(category) ?? '';
    final safeUrl = url ?? '';

    List<PendingEqub> activeEqubs = [];
    // setState(() {
    totalEqubs = activeEqubs.length;
    // });
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: safeUrl.isEmpty
          ? FutureBuilder<List<PendingEqub>>(
              future: getMyEkubs(
                  type: safeType, url: safeUrl, category: safeCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Align(
                    alignment: Alignment.topCenter,
                    child: SpinKitFadingCircle(
                      color: AppColors.black,
                      size: 50.0,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          textScaleFactor: 1.0,
                          AppKeys.errorTryAgain.tr(context)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Align(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          SizedBox(
                              height: 90,
                              width: 100,
                              child: Image.asset("assets/warning sign.png")),
                          const SizedBox(height: 20),
                          Text(
                            textScaleFactor: 1.0,
                            AppKeys.noActiveEqubs.tr(context),
                            style: AppTextStyles.sectionTitle,
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  activeEqubs = snapshot.data!
                      .where((e) =>
                          e.status.trim().toLowerCase() != AppKeys.completed)
                      .toList();
                  PendingEqub.sortByLatestJoined(activeEqubs);

                  if (activeEqubs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            SizedBox(
                                height: 90,
                                width: 100,
                                child: Image.asset("assets/warning sign.png"),),
                            const SizedBox(height: 20),
                            Text(
                              textScaleFactor: 1.0,
                              AppKeys.noActiveEqubs.tr(context),
                              style: AppTextStyles.sectionTitle,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: activeEqubs.length,
                    padding: const EdgeInsets.all(2),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 5.0, left: 5),
                        child: Card(
                          child: Container(
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                              gradient: LinearGradient(
                                begin: Alignment.center,
                                end: Alignment.centerLeft,
                                colors: [
                                  AppColors.deepForest,
                                  AppColors.deepOliveGreenB,
                                ],
                              ),
                            ),
                            height: 106.h,
                            width: 355.w,
                            padding: const EdgeInsets.only(),
                            child: Stack(
                              children: [
                               
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 50,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.loop_rounded,
                                          size: 18,
                                          color: AppColors.white,
                                        ),
                                        Text(
                                          textScaleFactor: 1.0,
                                          activeEqubs[index]
                                              .numberOfEqubers
                                              .toString(),
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        textScaleFactor: 1.0,
                                        activeEqubs[index].name,
                                        style: AppTextStyles.listTitle.copyWith(
                                          color: AppColors.white,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120.w,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            textScaleFactor: 1.0,
                                            numberFormat.format(int.parse(
                                                    activeEqubs[index]
                                                        .equbAmount
                                                        .toString()) *
                                                int.parse(activeEqubs[index]
                                                    .numberOfEqubers
                                                    .toString())),
                                            style: AppTextStyles.screenTitle
                                                .copyWith(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 20,
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            if (activeEqubs[index]
                                                    .nextRoundDate !=
                                                null) {
                                              String updatedDateTime =
                                                  '${activeEqubs[index].nextRoundDate!.substring(0, 11)}${activeEqubs[index].nextRoundTime}:00Z';

                                              DateTime targetDateTime =
                                                  DateTime.parse(
                                                      updatedDateTime);

                                              DateTime serverTime =
                                                  await fetchServerTime();

                                              final now = serverTime;
                                              Duration remainingTime =
                                                  targetDateTime
                                                      .difference(now);

                                              activeEqubs[index]
                                                      .equbCategory!
                                                      .isSaving
                                                  ? Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              SavingEkubDetail(
                                                                equbersId:
                                                                    activeEqubs[
                                                                            index]
                                                                        .equbers!
                                                                        .first
                                                                        .id,
                                                                savingEkubName:
                                                                    activeEqubs[
                                                                            index]
                                                                        .name,
                                                                ekubId:
                                                                    activeEqubs[
                                                                            index]
                                                                        .id,
                                                                serviceCharge:
                                                                    activeEqubs[
                                                                            index]
                                                                        .serviceCharge
                                                                        .toString(),
                                                                nextRoundTime:
                                                                    activeEqubs[index]
                                                                            .nextRoundTime ??
                                                                        '',
                                                                ekubCycle:
                                                                    activeEqubs[
                                                                            index]
                                                                        .numberOfEqubers,
                                                                nextRoundDate:
                                                                    activeEqubs[index]
                                                                            .nextRoundDate ??
                                                                        '',
                                                                ekubAmount: activeEqubs[
                                                                            index]
                                                                        .equbAmount *
                                                                    activeEqubs[
                                                                            index]
                                                                        .numberOfEqubers,
                                                                ekubName:
                                                                    activeEqubs[
                                                                            index]
                                                                        .name,
                                                                ekubersNumber: activeEqubs[index]
                                                                            .equbers !=
                                                                        []
                                                                    ? activeEqubs[
                                                                            index]
                                                                        .equbers!
                                                                        .length
                                                                    : 0,
                                                                nextRoundLotteryType:
                                                                    activeEqubs[
                                                                            index]
                                                                        .nextRoundLotteryType,
                                                                ekubRequest: activeEqubs[
                                                                            index]
                                                                        .equbCategory
                                                                        ?.needsRequest ??
                                                                    false,
                                                              )))
                                                  : remainingTime.inSeconds <=
                                                          65
                                                      ? CustomSnackBar.show(
                                                          context,
                                                          "Less than 1 minute to draw this equb. Please check out the winner after a minute under lotteries",
                                                          AppColors.blue)
                                                      : Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  MyEkubDetailScreen(
                                                                    ekubType: activeEqubs[index]
                                                                            .equbCategory
                                                                            ?.name ??
                                                                        'Finance',
                                                                    serviceCharge: activeEqubs[
                                                                            index]
                                                                        .serviceCharge
                                                                        .toString(),
                                                                    nextRoundTime:
                                                                        activeEqubs[index].nextRoundTime ??
                                                                            '',
                                                                    ekubCycle: activeEqubs[
                                                                            index]
                                                                        .numberOfEqubers,
                                                                    nextRoundDate:
                                                                        activeEqubs[index].nextRoundDate ??
                                                                            '',
                                                                    ekubAmount: activeEqubs[index]
                                                                            .equbAmount *
                                                                        activeEqubs[index]
                                                                            .numberOfEqubers,
                                                                    ekubName:
                                                                        activeEqubs[index]
                                                                            .name,
                                                                    ekubersNumber: activeEqubs[index].equbers !=
                                                                            []
                                                                        ? activeEqubs[index]
                                                                            .equbers!
                                                                            .length
                                                                        : 0,
                                                                    nextRoundLotteryType:
                                                                        activeEqubs[index]
                                                                            .nextRoundLotteryType,
                                                                    ekubId:
                                                                        activeEqubs[index]
                                                                            .id,
                                                                    ekubRequest: activeEqubs[index]
                                                                            .equbCategory
                                                                            ?.needsRequest ??
                                                                        false,
                                                                  )));
                                            } else {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SavingEkubDetail(
                                                    equbersId:
                                                        activeEqubs[index]
                                                            .equbers!
                                                            .first
                                                            .id,
                                                    savingEkubName:
                                                        activeEqubs[index].name,
                                                    ekubId:
                                                        activeEqubs[index].id,
                                                    serviceCharge:
                                                        activeEqubs[index]
                                                            .serviceCharge
                                                            .toString(),
                                                    nextRoundTime: activeEqubs[
                                                                index]
                                                            .nextRoundTime ??
                                                        '',
                                                    ekubCycle:
                                                        activeEqubs[index]
                                                            .numberOfEqubers,
                                                    nextRoundDate: activeEqubs[
                                                                index]
                                                            .nextRoundDate ??
                                                        '',
                                                    ekubAmount: activeEqubs[
                                                                index]
                                                            .equbAmount *
                                                        activeEqubs[index]
                                                            .numberOfEqubers,
                                                    ekubName:
                                                        activeEqubs[index].name,
                                                    ekubersNumber:
                                                        activeEqubs[index]
                                                                    .equbers !=
                                                                []
                                                            ? activeEqubs[index]
                                                                .equbers!
                                                                .length
                                                            : 0,
                                                    nextRoundLotteryType:
                                                        activeEqubs[index]
                                                            .nextRoundLotteryType,
                                                    ekubRequest: activeEqubs[
                                                                index]
                                                            .equbCategory
                                                            ?.needsRequest ??
                                                        false,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          style: const ButtonStyle(
                                              backgroundColor:
                                                  WidgetStatePropertyAll(
                                                      AppColors.white)),
                                          child: Text(
                                            textScaleFactor: 1.0,
                                            AppKeys.details.tr(context),
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                color: AppColors.black),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                               
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              })
          : FutureBuilder<f.FinanceAndOtherResponse>(
              future:
                  _fetchFinanceAndOtherData(safeType, safeCategory, safeUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Align(
                    alignment: Alignment.topCenter,
                    child: SpinKitFadingCircle(
                      color: AppColors.black,
                      size: 50.0,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Text(AppKeys.errorTryAgain),
                  );
                } else if (!snapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Align(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 130,
                            width: 139,
                            child: Image.asset("assets/warning sign.png"),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            AppKeys.noActiveEqubs.tr(context),
                            style: AppTextStyles.screenTitle,
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // Call the method to merge the data
                  final activeEqubs = snapshot.data!;

                  return FutureBuilder<List<f.UserData>>(
                    future: mergeJoinedEqubs(
                        activeEqubs!.data!.financeAndCar ?? []),
                    builder: (context, mergedDataSnapshot) {
                      if (mergedDataSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Align(
                          alignment: Alignment.topCenter,
                          child: SpinKitFadingCircle(
                            color: AppColors.black,
                            size: 50.0,
                          ),
                        );
                      } else if (mergedDataSnapshot.hasError) {
                        return Center(
                          child: Text(AppKeys.errorTryAgain.tr(context)),
                        );
                      } else if (!mergedDataSnapshot.hasData ||
                          mergedDataSnapshot.data!.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Align(
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                SizedBox(
                                    height: 90,
                                    width: 100,
                                    child:
                                        Image.asset("assets/warning sign.png")),
                                const SizedBox(height: 20),
                                Text(
                                  textScaleFactor: 1.0,
                                  AppKeys.noActiveEqubs.tr(context),
                                  style: AppTextStyles.sectionTitle,
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        List<f.UserData> mergedData = mergedDataSnapshot.data!;

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: mergedData.length,
                          padding: const EdgeInsets.all(2),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: 5.0, left: 5),
                              child: Card(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(8)),
                                    gradient: LinearGradient(
                                      begin: Alignment.center,
                                      end: Alignment.centerLeft,
                                      colors: [
                                        AppColors.deepForest,
                                        AppColors.richDeepGreen,
                                      ],
                                    ),
                                  ),
                                  height: 106.h,
                                  width: 355.w,
                                  padding: const EdgeInsets.only(),
                                  child: Stack(
                                    children: [
                                      // Positioned(
                                      //   left: 0,
                                      //   top: 0,
                                      //   bottom: 50,
                                      //   child: Padding(
                                      //     padding:
                                      //         const EdgeInsets.only(left: 8.0),
                                      //     child: Row(
                                      //       mainAxisAlignment:
                                      //           MainAxisAlignment.center,
                                      //       children: [
                                      //         const Icon(
                                      //           Icons.people_alt_outlined,
                                      //           size: 18,
                                      //           color: AppColors.white,
                                      //         ),
                                      //         Padding(
                                      //           padding: const EdgeInsets.only(
                                      //               left: 5.0),
                                      //           child: Text(
                                      //             mergedData[index]
                                      //                 .joinedEqubs!.first
                                      //                 .equberCount
                                      //                 .toString(),
                                      //             style: AppTextStyles.caption.copyWith(
                                      //               color: AppColors.white,
                                      //             ),
                                      //           ),
                                      //         ),
                                      //       ],
                                      //     ),
                                      //   ),
                                      // ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        bottom: 50,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.loop_rounded,
                                                size: 18,
                                                color: AppColors.white,
                                              ),
                                              Text(
                                                mergedData[index]
                                                        .joinedEqubs?.first
                                                        .numberOfEqubers
                                                        .toString() ??
                                                    '',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                  color: AppColors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              mergedData[index]
                                                      .joinedEqubs?.first
                                                      .name ??
                                                  '',
                                              style: AppTextStyles.listTitle
                                                  .copyWith(
                                                color: AppColors.white,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 120.w,
                                              child: FittedBox(
                                                fit: BoxFit.fill,
                                                child: Text(
                                                  numberFormat.format(int.parse(
                                                          mergedData[index]
                                                                  .joinedEqubs
                                                                  ?.first
                                                                  .equbAmount
                                                                  .toString() ??
                                                              '0') *
                                                      int.parse(mergedData[
                                                                  index]
                                                              .joinedEqubs
                                                              ?.first
                                                              .numberOfEqubers
                                                              .toString() ??
                                                          '0')),
                                                  style: AppTextStyles.screenTitle
                                                      .copyWith(
                                                    color: AppColors.white,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 20,
                                              child: OutlinedButton(
                                                style: const ButtonStyle(
                                                    backgroundColor:
                                                        WidgetStatePropertyAll(
                                                            AppColors.white)),
                                                onPressed: () async {
                                                  if (mergedData[index]
                                                          .joinedEqubs!.first
                                                          .nextRoundDate !=
                                                      null) {
                                                    String updatedDateTime =
                                                        '${mergedData[index].joinedEqubs!.first.nextRoundDate!.substring(0, 11)}${mergedData[index].joinedEqubs!.first.nextRoundTime}:00Z';

                                                    DateTime targetDateTime =
                                                        DateTime.parse(
                                                            updatedDateTime);

                                                    DateTime serverTime =
                                                        await fetchServerTime();

                                                    final now = serverTime;
                                                    Duration remainingTime =
                                                        targetDateTime
                                                            .difference(now);

                                                    mergedData[index]
                                                                .joinedEqubs!
                                                                .first
                                                                .equbCategory!
                                                                .isSaving ??
                                                            false
                                                        ? Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  SavingEkubDetail(
                                                                equbersId: mergedData[
                                                                        index]
                                                                    .joinedEqubs!.first
                                                                    .id!,
                                                                savingEkubName: mergedData[
                                                                            index]
                                                                        .joinedEqubs!.first
                                                                        .name ??
                                                                    '',
                                                                ekubId: mergedData[
                                                                        index]
                                                                    .joinedEqubs!.first
                                                                    .id!,
                                                                serviceCharge: mergedData[
                                                                        index]
                                                                    .joinedEqubs!.first
                                                                    .serviceCharge
                                                                    .toString(),
                                                                nextRoundTime: mergedData[
                                                                            index]
                                                                        .joinedEqubs!.first
                                                                        .nextRoundTime ??
                                                                    '',
                                                                ekubCycle: mergedData[
                                                                            index]
                                                                        .joinedEqubs!.first
                                                                        .numberOfEqubers ??
                                                                    0,
                                                                nextRoundDate: mergedData[
                                                                            index]
                                                                        .joinedEqubs!.first
                                                                        .nextRoundDate ??
                                                                    '',
                                                                ekubAmount: mergedData[
                                                                            index]
                                                                        .joinedEqubs!.first
                                                                        .equbAmount! *
                                                                    mergedData[
                                                                            index]
                                                                        .joinedEqubs!.first
                                                                        .numberOfEqubers!,
                                                                ekubName: mergedData[
                                                                            index]
                                                                        .joinedEqubs!.first
                                                                        .name ??
                                                                    '',
                                                                ekubersNumber: mergedData[
                                                                            index]
                                                                        .joinedEqubs!.first
                                                                        .equberCount ??
                                                                    0,
                                                                nextRoundLotteryType: mergedData[
                                                                            index]
                                                                        .joinedEqubs!.first
                                                                        .nextRoundLotteryType ??
                                                                    '',
                                                                ekubRequest: mergedData[
                                                                            index]
                                                                        .joinedEqubs!.first
                                                                        .equbCategory
                                                                        ?.needsRequest ??
                                                                    false,
                                                              ),
                                                            ),
                                                          )
                                                        : remainingTime
                                                                    .inSeconds <=
                                                                65
                                                            ? CustomSnackBar.show(
                                                                context,
                                                                "Less than 1 minute to draw this equb. Please check out the winner after a minute under lotteries",
                                                                AppColors.blue)
                                                            : Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          MyEkubDetailScreen(
                                                                    ekubType: mergedData[index]
                                                                            .joinedEqubs!.first
                                                                            .equbCategory
                                                                            ?.name ??
                                                                        'Finance',
                                                                    serviceCharge: mergedData[
                                                                            index]
                                                                        .joinedEqubs!.first
                                                                        .serviceCharge
                                                                        .toString(),
                                                                    nextRoundTime:
                                                                        mergedData[index].joinedEqubs!.first.nextRoundTime ??
                                                                            '',
                                                                    ekubCycle: mergedData[
                                                                            index]
                                                                        .joinedEqubs!.first
                                                                        .numberOfEqubers!,
                                                                    nextRoundDate:
                                                                        mergedData[index].joinedEqubs!.first.nextRoundDate ??
                                                                            '',
                                                                    ekubAmount: mergedData[index]
                                                                            .joinedEqubs!.first
                                                                            .equbAmount! *
                                                                        mergedData[index]
                                                                            .joinedEqubs!.first
                                                                            .numberOfEqubers!,
                                                                    ekubName: mergedData[index]
                                                                            .joinedEqubs!.first
                                                                            .name ??
                                                                        '',
                                                                    ekubersNumber:
                                                                        mergedData[index].joinedEqubs!.first.equberCount ??
                                                                            0,
                                                                    nextRoundLotteryType:
                                                                        mergedData[index].joinedEqubs!.first.nextRoundLotteryType ??
                                                                            "",
                                                                    ekubId: mergedData[
                                                                            index]
                                                                        .joinedEqubs!.first
                                                                        .id!,
                                                                    ekubRequest: mergedData[index]
                                                                            .joinedEqubs!.first
                                                                            .equbCategory
                                                                            ?.needsRequest ??
                                                                        false,
                                                                  ),
                                                                ),
                                                              );
                                                  } else {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            SavingEkubDetail(
                                                          equbersId:
                                                              mergedData[index]
                                                                  .joinedEqubs!.first
                                                                  .id!,
                                                          savingEkubName:
                                                              mergedData[index]
                                                                      .joinedEqubs!.first
                                                                      .name ??
                                                                  '',
                                                          ekubId:
                                                              mergedData[index]
                                                                  .joinedEqubs!.first
                                                                  .id!,
                                                          serviceCharge:
                                                              mergedData[index]
                                                                  .joinedEqubs!.first
                                                                  .serviceCharge
                                                                  .toString(),
                                                          nextRoundTime: mergedData[
                                                                      index]
                                                                  .joinedEqubs!.first
                                                                  .nextRoundTime ??
                                                              '',
                                                          ekubCycle: mergedData[
                                                                  index]
                                                              .joinedEqubs!.first
                                                              .numberOfEqubers!,
                                                          nextRoundDate: mergedData[
                                                                      index]
                                                                  .joinedEqubs!.first
                                                                  .nextRoundDate ??
                                                              '',
                                                          ekubAmount: mergedData[
                                                                      index]
                                                                  .joinedEqubs!.first
                                                                  .equbAmount! *
                                                              mergedData[index]
                                                                  .joinedEqubs!.first
                                                                  .numberOfEqubers!,
                                                          ekubName: mergedData[
                                                                      index]
                                                                  .joinedEqubs!.first
                                                                  .name ??
                                                              '',
                                                          ekubersNumber: mergedData[
                                                                      index]
                                                                  .joinedEqubs!.first
                                                                  .equberCount ??
                                                              0,
                                                          nextRoundLotteryType:
                                                              mergedData[index]
                                                                      .joinedEqubs!.first
                                                                      .nextRoundLotteryType ??
                                                                  '',
                                                          ekubRequest: mergedData[
                                                                      index]
                                                                  .joinedEqubs!.first
                                                                  .equbCategory
                                                                  ?.needsRequest ??
                                                              false,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: Text(
                                                  AppKeys.details.tr(context),
                                                  style: AppTextStyles.bodyMedium
                                                      .copyWith(
                                                      color: AppColors.black),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(
                                                top: mergedData[index]
                                                            .joinedEqubs!.first
                                                            .equbCategory
                                                            ?.name ==
                                                        "Finance"
                                                    ? 25.0
                                                    : mergedData[index]
                                                                .joinedEqubs!.first
                                                                .equbCategory
                                                                ?.name ==
                                                            "Special Finance"
                                                        ? 32
                                                        : 34,
                                                right: 20),
                                            child: Image.asset(
                                              getImagePath(
                                                  mergedData[index]
                                                          .joinedEqubs!.first
                                                          .equbCategory
                                                          ?.name ??
                                                      'Finance',
                                                  true), // Replace 'Finance' with the appropriate category
                                              height: mergedData[index]
                                                          .joinedEqubs!.first
                                                          .equbCategory
                                                          ?.name ==
                                                      "Finance"
                                                  ? 92.h
                                                  : mergedData[index]
                                                              .joinedEqubs!.first
                                                              .equbCategory
                                                              ?.name ==
                                                          "Special Finance"
                                                      ? 52
                                                      : 42.h,
                                              width: mergedData[index]
                                                          .joinedEqubs!.first
                                                          .equbCategory
                                                          ?.name ==
                                                      "Finance"
                                                  ? 92
                                                  : mergedData[index]
                                                              .joinedEqubs!.first
                                                              .equbCategory
                                                              ?.name ==
                                                          "Special Finance"
                                                      ? 52
                                                      : 66,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: mergedData[index]
                                                          .joinedEqubs!.first
                                                          .equbCategory
                                                          ?.name ==
                                                      "Finance"
                                                  ? 5.h
                                                  : mergedData[index]
                                                              .joinedEqubs!.first
                                                              .equbCategory
                                                              ?.name ==
                                                          "Special Finance"
                                                      ? 32.h
                                                      : 34.h,
                                              left: 78.w,
                                            ),
                                            child: Image.asset(
                                              getImagePath(
                                                  mergedData[index]
                                                          .joinedEqubs!.first
                                                          .equbCategory
                                                          ?.name ??
                                                      'Finance',
                                                  false), // Replace 'Savings' with the appropriate category
                                              height: mergedData[index]
                                                          .joinedEqubs!.first
                                                          .equbCategory
                                                          ?.name ==
                                                      "Finance"
                                                  ? 92.h
                                                  : mergedData[index]
                                                              .joinedEqubs!.first
                                                              .equbCategory
                                                              ?.name ==
                                                          "Special Finance"
                                                      ? 52.h
                                                      : 42.h,
                                              width: mergedData[index]
                                                          .joinedEqubs!.first
                                                          .equbCategory
                                                          ?.name ==
                                                      "Finance"
                                                  ? 82.w
                                                  : mergedData[index]
                                                              .joinedEqubs!.first
                                                              .equbCategory
                                                              ?.name ==
                                                          "Special Finance"
                                                      ? 64.w
                                                      : 72.w,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  );
                }
              },
            ),
    );
  }

  String _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'finance':
        return "assets/birr.png";
      case 'car':
        return "assets/car.png";
      case 'house':
        return "assets/home1.png";
      case 'travel':
        return "assets/lefttravel.png";
      case 'special finance':
        return "assets/special1.png";
      default:
        return "assets/birr.png";
    }
  }
}


