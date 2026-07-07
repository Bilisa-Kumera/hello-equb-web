// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:dio/dio.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/models/ekub_category_model.dart';
import 'package:helloequb/models/financeandothermodel.dart' as f;
import 'package:helloequb/screens/home_screen.dart';
import 'package:helloequb/screens/my_ekub_detail_screen.dart';
import 'package:helloequb/screens/profile_screen.dart';
import 'package:helloequb/screens/saving_ekub_detail.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/custom_bottom_nav.dart';
import 'package:helloequb/utils/custom_snack_bar.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:helloequb/provider/equb_type_provider.dart' as type_provider;
import 'package:helloequb/provider/equb_category_provider.dart';
import 'package:helloequb/provider/getmyequb_provider.dart';
import 'package:helloequb/screens/my_equb_screen.dart';

import 'package:helloequb/utils/getx_storage_custom.dart' show DataController;
import 'package:helloequb/utils/lang_constants.dart' show AppKeys;

import '../utils/secure_storage.dart';
import 'allequb_payment.dart';
import 'pending_equbs_screen.dart';

class ActiveEqubsScreen extends StatefulWidget {
  const ActiveEqubsScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    stopProgressAfterDelay();
    loadEkubCategories();
    _mainTabController = TabController(length: 2, vsync: this);
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
        List<PendingEqub> freshData =
            pendingEqubsJson.map((json) => PendingEqub.fromJson(json)).toList();

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
      setState(() {
        progress = false;
      });
    });
  }

  int ekubTypeIndex = 0;
  int selectedEqubTypeIndex = 0;

  void _fetchEqubsForCurrentSelection(
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
      getMyEqubProvider.fetchEqubs(
        equbTypeId: typeId,
        equbCategoryId: catId,
        userId: userId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.forestGreenPrimary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppKeys.myEkub.tr(context),
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontWeight: FontWeight.bold,
                        fontSize: 32.sp,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppKeys.trackAll.tr(context),
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontWeight: FontWeight.w400,
                            fontSize: 16.sp,
                            color: Colors.white70,
                          ),
                        ),
                        Center(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
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
                                SizedBox(width: 8.w),
                                Text(
                                  AppKeys.pendingEkubs.tr(context).length > 10
                                      ? AppKeys.pendingEkubs
                                          .tr(context)
                                          .substring(0, 10)
                                      : AppKeys.pendingEkubs.tr(context),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.clip,
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
        bottomNavigationBar: CustomBottomNavigationBar(
          currentIndex: 1,
          onTap: (index) async {
            switch (index) {
              case 0:
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HomeScreen()));

                break;
              case 1:
                break;
              case 2:
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PaymentList()));
                break;
              case 3:
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()));
                break;
              default:
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HomeScreen()));
                break;
            }
          },
        ),
      ),
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

  Widget _buildTabContent(int index, {String? url}) {
    return ChangeNotifierProvider(
      create: (_) => GetMyEqubProvider(),
      child: Consumer2<type_provider.EqubTypeProvider, EqubCategoryProvider>(
        builder: (context, typeProvider, categoryProvider, _) {
          final types =
              typeProvider.equbTypes?.where((t) => t.id != null).toList() ?? [];
          final categories = categoryProvider.equbCategories
                  ?.where((c) => c.id != null)
                  .toList() ??
              [];

          // Build filteredCategories FIRST before any conditional returns
          final filteredCategories = [
            EqubCategory(
                id: '',
                name: AppKeys.all.tr(context),
                createdAt: '',
                description: '',
                hasReason: false,
                needsRequest: false,
                state: '',
                updatedAt: ""),
            ...categories
          ];

          // Now check if types are empty
          if (types.isEmpty) {
            return Center(
              child: LoadingAnimationWidget.threeRotatingDots(
                color: AppColors.vibrantGreen,
                size: 30,
              ),
            );
          }

          // Ensure selected indices are valid AFTER we have data
          if (selectedEqubTypeIndex >= types.length) {
            selectedEqubTypeIndex = 0;
          }
          
          // CRITICAL FIX: Ensure selectedCategoryIndex is valid for filteredCategories
          if (selectedCategoryIndex >= filteredCategories.length) {
            selectedCategoryIndex = 0;
          }

          // Fetch data once when we have both types and categories
          if (!_hasFetchedInitial && types.isNotEmpty) {
            _hasFetchedInitial = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchEqubsForCurrentSelection(context, types, filteredCategories);
            });
          }

          if (filteredCategories.isEmpty) {
            return Center(child: Text(AppKeys.noCategories.tr(context)));
          }

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      // KEY FIX: Use a ValueKey to force rebuild when categories change
                      key: ValueKey('category_dropdown_${filteredCategories.length}_${selectedCategoryIndex}'),
                      value: selectedCategoryIndex < filteredCategories.length 
                          ? selectedCategoryIndex 
                          : 0,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(16),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Urbanist',
                        color: Colors.black,
                      ),
                      items: List.generate(
                        filteredCategories.length,
                        (index) => DropdownMenuItem(
                          value: index,
                          child:
                              Text(filteredCategories[index].name ?? 'Unknown'),
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
                height: 76.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: types.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, idx) {
                    final type = types[idx];
                    final isSelected = idx == selectedEqubTypeIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedEqubTypeIndex = idx;
                          selectedCategoryIndex = 0; // Reset to "All" when type changes
                        });
                        _fetchEqubsForCurrentSelection(
                            context, types, filteredCategories);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: EdgeInsets.symmetric(
                            horizontal: 26.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color:
                                          AppColors.primary.withOpacity(0.18),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2))
                                ]
                              : [],
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          type.name ?? 'Unknown',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade700,
                            fontFamily: 'Urbanist',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Equb list
              Expanded(
                child: Consumer<GetMyEqubProvider>(
                  builder: (context, equbProvider, _) {
                    if (equbProvider.isLoading && equbProvider.equbs.isEmpty) {
                      return Center(
                        child: LoadingAnimationWidget.threeRotatingDots(
                          color: AppColors.vibrantGreen,
                          size: 30,
                        ),
                      );
                    } else if (equbProvider.errorMessage != null) {
                      return Center(child: Text(AppKeys.errorTryAgain.tr(context)));
                    }

                    final visibleEqubs = equbProvider.equbs
                        .where((e) =>
                            e.status.trim().toLowerCase() != AppKeys.completed)
                        .toList();

                    if (visibleEqubs.isEmpty) {
                      return Center(child: Text(AppKeys.noEkubs.tr(context)));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      separatorBuilder: (_, __) => const SizedBox(height: 24),
                      itemCount: visibleEqubs.length,
                      itemBuilder: (context, idx) {
                        final equb = visibleEqubs[idx];
                        final accentColor = AppColors.primary.withOpacity(0.13);

                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 350 + idx * 60),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: child),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: LinearGradient(
                                colors: [
                                  accentColor,
                                  Colors.white.withOpacity(0.92)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color: accentColor,
                                    blurRadius: 18,
                                    offset: const Offset(0, 8))
                              ],
                              border: Border.all(
                                  color: AppColors.primary.withOpacity(0.12),
                                  width: 1.5),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 10.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 42.h,
                                  width: 42.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.13),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: Image.asset(
                                    _getCategoryIcon(equb.equbCategory?.name),
                                    height: 62.h,
                                    width: 62.w,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              equb.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 17,
                                                fontFamily: 'Urbanist',
                                                color: AppColors.primary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.blue,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              equb.status.toLowerCase().tr(context),
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.money,
                                              size: 16,
                                              color: AppColors.primary),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${equb.equbAmount}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.people,
                                              size: 15, color: Colors.grey),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${equb.numberOfEqubers}',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Material(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(22),
                                  elevation: 2,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(22),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MyEkubDetailScreen(
                                            ekubType: equb.equbCategory?.name ??
                                                'Finance',
                                            serviceCharge:
                                                equb.serviceCharge.toString(),
                                            nextRoundTime:
                                                equb.nextRoundTime ?? '',
                                            ekubCycle: equb.numberOfEqubers,
                                            nextRoundDate:
                                                equb.nextRoundDate ?? '',
                                            ekubAmount: equb.equbAmount *
                                                equb.numberOfEqubers,
                                            ekubName: equb.name,
                                            ekubersNumber:
                                                equb.equbers?.length ?? 0,
                                            nextRoundLotteryType:
                                                equb.nextRoundLotteryType,
                                            ekubId: equb.id,
                                            ekubRequest: equb.equbCategory
                                                    ?.needsRequest ??
                                                false,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.arrow_forward_ios,
                                              color: Colors.white, size: 15),
                                          const SizedBox(width: 5),
                                          Text(AppKeys.details.tr(context),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  fontFamily: 'Urbanist')),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
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
                            style: TextStyle(
                                fontSize: 18.sp, fontWeight: FontWeight.w600),
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
                              style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600),
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
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w400,
                                            fontSize: 12,
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
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
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
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 24.sp,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.white,
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
                                            style: const TextStyle(
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
                            style: TextStyle(
                                fontSize: 24.sp, fontWeight: FontWeight.w600),
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
                                  style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600),
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
                                      //             style: const TextStyle(
                                      //               fontFamily: 'Poppins',
                                      //               fontWeight: FontWeight.w400,
                                      //               fontSize: 12,
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
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 12,
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
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
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
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w900,
                                                    color: AppColors.white,
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
                                                  style: const TextStyle(
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


