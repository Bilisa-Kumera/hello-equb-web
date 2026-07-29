// ignore_for_file: deprecated_member_use

import 'package:dio/dio.dart';
import 'package:helloequb/core/api_service_elper.dart';
import 'package:helloequb/screens/join_ekub_detail.dart';
import 'package:helloequb/screens/my_other_ekubs.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/style_constants.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/utils/equb_type_localization.dart';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/screens/equb_category_screen.dart';
import 'package:helloequb/screens/profile_screen.dart';
import 'package:helloequb/screens/notification_screen.dart';

import 'package:helloequb/utils/custom_bottom_nav.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:helloequb/provider/banner_provider.dart';
import 'package:helloequb/models/banner_model.dart';
import 'package:helloequb/provider/equb_type_provider.dart';
import 'package:helloequb/provider/equb_category_provider.dart';
import 'package:helloequb/provider/equb_provider.dart';
import 'package:helloequb/provider/cooperate_equbs_provider.dart';
import 'package:helloequb/models/cooperate_models.dart';
import 'package:helloequb/provider/joined_equbs_status_provider.dart';
import 'package:helloequb/utils/main_nav_helper.dart';

import '../utils/getx_storage_custom.dart';
import '../utils/secure_storage.dart';
import 'LoginScreenWithPin.dart';
import 'allequb_payment.dart';
import 'cooperate_list_screen.dart';
import 'equb_detail_card.dart';

class EqubTabbedScreen extends StatefulWidget {
  final EqubCategory category;
  final List<EqubType> equbTypes;
  final String equbTypeId;
  final String equbType;
  final String? imageUrl;
  final String? description;

  const EqubTabbedScreen(
      {super.key,
      required this.category,
      required this.equbTypes,
      required this.equbTypeId,
      required this.equbType,
      this.imageUrl,
      this.description});

  @override
  State<EqubTabbedScreen> createState() => _EqubTabbedScreenState();
}

class _EqubTabbedScreenState extends State<EqubTabbedScreen> {
  @override
  Widget build(BuildContext context) {
    final List<EqubType> equbTypesWithAll = [
      EqubType(id: '', name: 'All'),
      ...widget.equbTypes,
    ];

    return DefaultTabController(
      length: equbTypesWithAll.length,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              )),
          backgroundColor: AppColors.primary,
          title: Row(
            children: [
              Text(
                widget.equbType,
                style: AppTextStyles.onPrimaryBold,
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                labelColor: AppColors.white,
                unselectedLabelColor: Colors.white70,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(
                    width: 3,
                    color: AppColors.white,
                  ),
                  insets: EdgeInsets.symmetric(horizontal: 16),
                ),
                tabs: equbTypesWithAll.map((equbType) {
                  return Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        translateEqubTypeName(
                          context,
                          equbType.name,
                          interval: equbType.interval,
                        ),
                        style: AppTextStyles.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: equbTypesWithAll.map((equbType) {
            return EqubListByCategory(
              category: widget.category,
              equbTypeId: equbType.id ?? '',
              type: equbType.name ?? '',
              imageUrl: widget.imageUrl,
              description: widget.description,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class EqubListByCategory extends StatefulWidget {
  final EqubCategory category;
  final String equbTypeId;
  final String type;
  final String? imageUrl;
  final String? description;

  const EqubListByCategory(
      {super.key,
      required this.category,
      required this.equbTypeId,
      required this.type,
      this.imageUrl,
      this.description});

  @override
  State<EqubListByCategory> createState() => _EqubListByCategoryState();
}

class _EqubListByCategoryState extends State<EqubListByCategory> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<EqubProvider>().fetchEqubs(
            equbCategoryId: widget.category.id ?? '',
            equbTypeId: widget.equbTypeId,
          );
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final provider = context.read<EqubProvider>();
    if (provider.isLoading || provider.isLoadingMore || !provider.hasMore) {
      return;
    }

    final pos = _scrollController.position;
    if (!pos.hasPixels) return;
    if (pos.pixels >= pos.maxScrollExtent - 320) {
      provider.loadMoreEqubs(
        equbCategoryId: widget.category.id ?? '',
        equbTypeId: widget.equbTypeId,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EqubProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
            child: LoadingAnimationWidget.threeRotatingDots(
              color: AppColors.vibrantGreen,
              size: 30,
            ),
          );
        }

        if (provider.error != null && provider.equbs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.error ?? 'Failed to load equbs',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.greyBody,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => context.read<EqubProvider>().fetchEqubs(
                          equbCategoryId: widget.category.id ?? '',
                          equbTypeId: widget.equbTypeId,
                        ),
                    child: Text(AppKeys.retry.tr(context)),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.equbs.isEmpty) {
          return Center(
            child: Text(
              AppKeys.noEkubs.tr(context),
              style: AppTextStyles.greyBody,
            ),
          );
        }

        final sortedEqubs = provider.equbs
            .where((equb) => equb.isActive == true)
            .toList()
          ..sort((a, b) => (a.equbAmount ?? 0).compareTo(b.equbAmount ?? 0));

        if (sortedEqubs.isEmpty) {
          return Center(
            child: Text(
              AppKeys.noActiveEqubs.tr(context),
              style: AppTextStyles.greyBody,
            ),
          );
        }

        final showBottomItem = provider.isLoadingMore || provider.hasMore;

        return ListView.separated(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 16.h),
          itemCount: sortedEqubs.length + (showBottomItem ? 1 : 0),
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            if (index >= sortedEqubs.length) {
              if (provider.error != null) {
                return Center(
                  child: TextButton(
                    onPressed: () => context.read<EqubProvider>().loadMoreEqubs(
                          equbCategoryId: widget.category.id ?? '',
                          equbTypeId: widget.equbTypeId,
                        ),
                    child: Text(AppKeys.retry.tr(context)),
                  ),
                );
              }
              if (!provider.isLoadingMore) {
                return const SizedBox(height: 60);
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: LoadingAnimationWidget.threeRotatingDots(
                    color: AppColors.vibrantGreen,
                    size: 26,
                  ),
                ),
              );
            }
            final equb = sortedEqubs[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EqubJoinDetail(
                      equb: equb,
                      equbType: equb.equbType?.entries.first.value ?? '',
                    ),
                  ),
                );
              },
              child: EqubDetailCard(
                key: ValueKey(equb.id),
                equb: equb,
                equbType: equb.equbType?.entries.first.value ?? '',
                type: equb.equbType?['name'],
                imageUrl: widget.imageUrl,
                image: equb.image,
                description: widget.description,
              ),
            );
          },
        );
      },
    );
  }
}

String getEqubIcon(String? name) {
  switch (name) {
    case "Car Equb":
      return "assets/care.png";
    case "House Equb":
      return "assets/home.png";
    default:
      return "assets/equb.png";
  }
}

class HomeScreen extends StatefulWidget {
  final bool embedInShell;

  const HomeScreen({super.key, this.embedInShell = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

int notificationCount = 0;

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<String> tabs = ['Daily', 'Weekly', 'Monthly'];
  String? fullName;

  String _firstAndMiddleName(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.take(2).join(' ');
  }

  int currentEqubTypeIndex = 0;
  int currentCategoryIndex = 0;
  bool _firstBuild = true;

  Future<void> _refreshHome() async {
    Provider.of<EqubTypeProvider>(context, listen: false).fetchEqubTypes();
    Provider.of<EqubCategoryProvider>(context, listen: false)
        .fetchEqubCategories();
    Provider.of<BannerProvider>(context, listen: false).fetchBanners();
    context.read<CooperateEqubsProvider>().fetchCooperates();
    _fetchEqubsForCurrentTab(context);
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  @override
  void initState() {
    super.initState();
    getProfileImage();
    dataController.initialize().then((_) {
      _updateFCMToken();
    });
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(() {
      if (_tabController!.indexIsChanging) {
        final newIndex = _tabController!.index;
        setState(() {
          currentEqubTypeIndex = newIndex;
          currentCategoryIndex = 0;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchEqubsForCurrentTab(context);
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CooperateEqubsProvider>().fetchCooperates();
    });
    Future.microtask(() =>
        Provider.of<EqubTypeProvider>(context, listen: false).fetchEqubTypes());
    Future.microtask(() =>
        Provider.of<EqubCategoryProvider>(context, listen: false)
            .fetchEqubCategories());
  }

  void _fetchEqubsForCurrentTab(BuildContext context) {
    final equbTypes =
        Provider.of<EqubTypeProvider>(context, listen: false).equbTypes ?? [];
    final equbCategories =
        Provider.of<EqubCategoryProvider>(context, listen: false)
                .equbCategories ??
            [];
    if (equbTypes.isNotEmpty && equbCategories.isNotEmpty) {
      final typeId = equbTypes[currentEqubTypeIndex].id;
      final categoryId = equbCategories[currentCategoryIndex].id;
      if (typeId != null && categoryId != null) {
        Provider.of<EqubProvider>(context, listen: false)
            .fetchEqubs(equbTypeId: typeId, equbCategoryId: categoryId);
      }
    }
  }

  void handleEqubTypeChange(
      int index, int max, List equbTypes, List equbCategories) {
    if (index < 0 || index >= max) return;
    setState(() {
      currentEqubTypeIndex = index;
      currentCategoryIndex = 0;
    });
    _fetchEqubsForCurrentTab(context);
  }

  void handleCategoryIndexChanged(int newIndex, int max) {
    if (newIndex < 0 || newIndex >= max) return;
    setState(() {
      currentCategoryIndex = newIndex;
    });
    _fetchEqubsForCurrentTab(context);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  String profileAvatarUrl = '';

  Future<void> getProfileImage() async {
    final cachedAvatar =
        dataController.retrieveData<String>('profileUrl') ?? '';
    if (cachedAvatar.isNotEmpty) {
      setState(() {
        profileAvatarUrl = cachedAvatar;
      });
      return;
    }

    String accessToken = await SecureStorageHelper.getAccessToken() ?? '';
    if (accessToken.isEmpty) return;
    final data = await apiService.readAll(profileUrl, bearerToken: accessToken);
    final avatar = data['user']?['avatar']?.toString() ?? '';
    if (avatar.isEmpty) return;
    dataController.storeData('profileUrl', avatar);
    setState(() {
      profileAvatarUrl = avatar;
    });
  }

  final DataController dataController = DataController();
  final ApiService apiService = ApiService();

  Future<void> _updateFCMToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();
      if (token != null) {
        String userId = await SecureStorageHelper.getUserId() ??
            await SecureStorageHelper.getUserId() ??
            '';
        String accessToken = await SecureStorageHelper.getAccessToken() ?? '';
        await SecureStorageHelper.getAccessToken() ?? '';
        await apiService.update(
          deviceTokenUrl,
          userId,
          {'token': token},
          bearerToken: accessToken,
        );
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BannerProvider()..fetchBanners(),
      child: Consumer3<EqubTypeProvider, EqubCategoryProvider, EqubProvider>(
        builder:
            (context, equbTypeProvider, equbCategoryProvider, equbProvider, _) {
          final equbTypes = equbTypeProvider.equbTypes ?? [];
          final equbCategories = equbCategoryProvider.equbCategories ?? [];

          if (_firstBuild &&
              equbTypes.isNotEmpty &&
              equbCategories.isNotEmpty) {
            _firstBuild = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchEqubsForCurrentTab(context);
            });
          }

          return GestureDetector(
            onTap: () {
              // InactivityService(onLogoutCallback: _logoutUser)
              // .updateInteractionTime();
            },
            child: RefreshIndicator(
              onRefresh: () {
                if (widget.embedInShell) {
                  return _refreshHome();
                }
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HomeScreen()));
                return Future<void>.delayed(const Duration(seconds: 3));
              },
              child: Scaffold(
                extendBody: !widget.embedInShell,
                backgroundColor: Colors.white,
                body: RefreshIndicator(
                  onRefresh: () {
                    if (widget.embedInShell) {
                      return _refreshHome();
                    }
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomeScreen()));
                    return Future<void>.delayed(const Duration(seconds: 3));
                  },
                  child: Container(
                      color: Colors.white,
                      child: ((equbTypeProvider.isLoading ?? false) ||
                              (equbCategoryProvider.isLoading == true))
                          ? Center(
                              child: LoadingAnimationWidget.threeRotatingDots(
                                color: AppColors.primary,
                                size: 30,
                              ),
                            )
                          : (equbTypeProvider.error != null ||
                                  equbCategoryProvider.error != null)
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.refresh,
                                            size: 40, color: AppColors.red),
                                        onPressed: () {
                                          Provider.of<EqubTypeProvider>(context,
                                                  listen: false)
                                              .fetchEqubTypes();
                                          Provider.of<EqubCategoryProvider>(
                                                  context,
                                                  listen: false)
                                              .fetchEqubCategories();
                                          Provider.of<BannerProvider>(context,
                                                  listen: false)
                                              .fetchBanners();
                                          _fetchEqubsForCurrentTab(context);
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Tap to refresh',
                                        style:
                                            AppTextStyles.sectionTitle.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                )
                              : CustomScrollView(
                                  shrinkWrap: true,
                                  slivers: [
                                    SliverAppBar(
                                      backgroundColor: Colors.white,
                                      elevation: 0,
                                      surfaceTintColor: Colors.white,
                                      leading: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 16.0, top: 20),
                                        child: GestureDetector(
                                          onTap: () => {},
                                          // _showProfileDialog(context),
                                          child: CircleAvatar(
                                            radius: 30,
                                            backgroundImage: profileAvatarUrl
                                                    .isNotEmpty
                                                ? NetworkImage(
                                                    '${mediaUrl}images/avatar/$profileAvatarUrl')
                                                : null,
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            child: profileAvatarUrl.isEmpty
                                                ? Icon(
                                                    Icons.person,
                                                    color: Colors.grey.shade600,
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ),
                                      title: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 18.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _firstAndMiddleName(
                                                dataController.retrieveData<
                                                    String>('fullName'),
                                              ),
                                              style: AppTextStyles.chipSelected
                                                  .copyWith(
                                                color: AppColors.richDeepGreen,
                                              ),
                                            ),
                                            Text(
                                              AppKeys.welcomeBack.tr(context),
                                              style: AppTextStyles.captionMuted
                                                  .copyWith(
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.notifications),
                                                color: AppColors.richDeepGreen,
                                                onPressed: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const NotificationScreen()));
                                                },
                                              ),
                                              if (notificationCount > 0)
                                                Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(
                                                            minWidth: 18,
                                                            minHeight: 18),
                                                    child: Center(
                                                      child: Text(
                                                        '$notificationCount',
                                                        style: AppTextStyles
                                                            .captionMuted
                                                            .copyWith(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      // pinned: true,
                                      // floating: true,
                                      // snap: true,
                                      expandedHeight: 220,
                                      flexibleSpace: FlexibleSpaceBar(
                                        background: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 68.0),
                                          child: Consumer<BannerProvider>(
                                            builder:
                                                (context, bannerProvider, _) {
                                              if (bannerProvider.isLoading) {
                                                return Center(
                                                  child: LoadingAnimationWidget
                                                      .threeRotatingDots(
                                                    color:
                                                        AppColors.vibrantGreen,
                                                    size: 30,
                                                  ),
                                                );
                                              } else if (bannerProvider.error !=
                                                  null) {
                                                return Center(
                                                    child: Text(
                                                        'Error: ${bannerProvider.error}'));
                                              } else if (bannerProvider
                                                  .banners.isEmpty) {
                                                return Center(
                                                    child: Text(
                                                  'No banners available',
                                                  style: AppTextStyles
                                                      .captionMuted
                                                      .copyWith(
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ));
                                              }
                                              return CarouselSlider(
                                                items: bannerProvider.banners
                                                    .map((banner) =>
                                                        _BannerCard(
                                                            banner: banner))
                                                    .toList(),
                                                options: CarouselOptions(
                                                  height: 140,
                                                  viewportFraction: 0.9,
                                                  enlargeCenterPage: true,
                                                  autoPlay: true,
                                                  autoPlayCurve:
                                                      Curves.fastOutSlowIn,
                                                  enableInfiniteScroll: true,
                                                  autoPlayAnimationDuration:
                                                      const Duration(
                                                          milliseconds: 800),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),

                                    // ======= Equb Types & Categories =======
                                    Consumer<CooperateEqubsProvider>(
                                      builder: (context, coopProv, _) {
                                        final hasMainCategories =
                                            equbCategories.any((cat) =>
                                                cat.otherTypeEqub == false);
                                        final hasOtherCategories =
                                            equbCategories.any((cat) =>
                                                cat.otherTypeEqub == true);
                                        final hasCooperates =
                                            coopProv.cooperates.isNotEmpty;

                                        if (!hasMainCategories &&
                                            !hasOtherCategories &&
                                            !hasCooperates) {
                                          return const SliverToBoxAdapter(
                                            child: SizedBox.shrink(),
                                          );
                                        }

                                        return SliverToBoxAdapter(
                                          child: Container(
                                            color: Colors.white,
                                            child: Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                  12.w, 8.h, 12.w, 16.h),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Builder(builder: (context) {
                                                    final filteredCategories =
                                                        equbCategories
                                                            .where((cat) =>
                                                                cat.otherTypeEqub ==
                                                                false)
                                                            .toList();

                                                    if (filteredCategories
                                                        .isEmpty) {
                                                      return const SizedBox
                                                          .shrink();
                                                    }

                                                    return Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .stretch,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  top: 8.h,
                                                                  bottom: 10.h),
                                                          child: Center(
                                                            child: Text(
                                                              AppKeys
                                                                  .joinEqubsToday
                                                                  .tr(context),
                                                              style: AppTextStyles
                                                                  .sectionTitle
                                                                  .copyWith(
                                                                color: AppColors
                                                                    .richDeepGreen,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        LayoutBuilder(
                                                          builder: (context,
                                                              constraints) {
                                                            const crossAxisCount =
                                                                3;
                                                            final spacing = 8.w;
                                                            final itemWidth = (constraints
                                                                        .maxWidth -
                                                                    spacing *
                                                                        (crossAxisCount -
                                                                            1)) /
                                                                crossAxisCount;
                                                            return Align(
                                                              alignment: Alignment
                                                                  .centerLeft,
                                                              child: Wrap(
                                                                alignment:
                                                                    WrapAlignment
                                                                        .start,
                                                                spacing:
                                                                    spacing,
                                                                runSpacing: 8.h,
                                                                children:
                                                                    filteredCategories
                                                                        .map(
                                                                            (category) {
                                                                  final networkUrl = (category.imageIcon !=
                                                                              null &&
                                                                          category
                                                                              .imageIcon!
                                                                              .isNotEmpty)
                                                                      ? '${mediaUrl}images/category/${category.imageIcon}'
                                                                      : null;
                                                                  return SizedBox(
                                                                    width:
                                                                        itemWidth,
                                                                    child:
                                                                        AspectRatio(
                                                                      aspectRatio:
                                                                          0.95,
                                                                      child:
                                                                          GestureDetector(
                                                                        onTap:
                                                                            () {
                                                                          Navigator
                                                                              .push(
                                                                            context,
                                                                            MaterialPageRoute(
                                                                              builder: (_) => EqubTabbedScreen(
                                                                                equbType: category.name ?? '',
                                                                                equbTypes: equbTypes,
                                                                                category: category,
                                                                                equbTypeId: category.id ?? '',
                                                                              ),
                                                                            ),
                                                                          );
                                                                        },
                                                                        child:
                                                                            Container(
                                                                          padding: EdgeInsets.fromLTRB(
                                                                              8.w,
                                                                              10.h,
                                                                              8.w,
                                                                              8.h),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                AppColors.white,
                                                                            borderRadius:
                                                                                BorderRadius.circular(12.r),
                                                                            border:
                                                                                Border.all(color: Colors.grey.shade200),
                                                                          ),
                                                                          child:
                                                                              Column(
                                                                            children: [
                                                                              Expanded(
                                                                                child: Center(
                                                                                  child: _HomeFallbackIcon(networkUrl: networkUrl),
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                category.name ?? '',
                                                                                style: AppTextStyles.labelSmall.copyWith(
                                                                                  fontWeight: FontWeight.w600,
                                                                                  color: AppColors.black,
                                                                                ),
                                                                                maxLines: 2,
                                                                                overflow: TextOverflow.ellipsis,
                                                                                textAlign: TextAlign.center,
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  );
                                                                }).toList(),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  }),
                                                  Builder(builder: (context) {
                                                    final otherCategories =
                                                        equbCategories
                                                            .where((cat) =>
                                                                cat.otherTypeEqub ==
                                                                true)
                                                            .toList();

                                                    if (otherCategories
                                                        .isEmpty) {
                                                      return const SizedBox
                                                          .shrink();
                                                    }

                                                    return Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .stretch,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  top: 16.h,
                                                                  bottom: 10.h),
                                                          child: Center(
                                                            child: Text(
                                                              AppKeys
                                                                  .otherEqubType
                                                                  .tr(context),
                                                              style: AppTextStyles
                                                                  .sectionTitle
                                                                  .copyWith(
                                                                color: AppColors
                                                                    .richDeepGreen,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        LayoutBuilder(
                                                          builder: (context,
                                                              constraints) {
                                                            const crossAxisCount =
                                                                3;
                                                            final spacing = 8.w;
                                                            final itemWidth = (constraints
                                                                        .maxWidth -
                                                                    spacing *
                                                                        (crossAxisCount -
                                                                            1)) /
                                                                crossAxisCount;
                                                            return Align(
                                                              alignment: Alignment
                                                                  .centerLeft,
                                                              child: Wrap(
                                                                alignment:
                                                                    WrapAlignment
                                                                        .start,
                                                                spacing:
                                                                    spacing,
                                                                runSpacing: 8.h,
                                                                children:
                                                                    otherCategories
                                                                        .map(
                                                                            (category) {
                                                                  final networkUrl = (category.imageIcon !=
                                                                              null &&
                                                                          category
                                                                              .imageIcon!
                                                                              .isNotEmpty)
                                                                      ? '${mediaUrl}images/category/${category.imageIcon}'
                                                                      : null;
                                                                  return SizedBox(
                                                                    width:
                                                                        itemWidth,
                                                                    child:
                                                                        AspectRatio(
                                                                      aspectRatio:
                                                                          0.95,
                                                                      child:
                                                                          GestureDetector(
                                                                        onTap:
                                                                            () {
                                                                          Navigator
                                                                              .push(
                                                                            context,
                                                                            MaterialPageRoute(
                                                                              builder: (_) => EqubTabbedScreen(
                                                                                imageUrl: category.imageIcon,
                                                                                description: category.description,
                                                                                equbType: category.name ?? '',
                                                                                equbTypes: equbTypes,
                                                                                category: category,
                                                                                equbTypeId: category.id ?? '',
                                                                              ),
                                                                            ),
                                                                          );
                                                                        },
                                                                        child:
                                                                            Container(
                                                                          padding: EdgeInsets.fromLTRB(
                                                                              8.w,
                                                                              10.h,
                                                                              8.w,
                                                                              8.h),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                AppColors.white,
                                                                            borderRadius:
                                                                                BorderRadius.circular(12.r),
                                                                            border:
                                                                                Border.all(color: Colors.grey.shade200),
                                                                          ),
                                                                          child:
                                                                              Column(
                                                                            children: [
                                                                              Expanded(
                                                                                child: Center(
                                                                                  child: _HomeFallbackIcon(networkUrl: networkUrl),
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                category.name ?? '',
                                                                                style: AppTextStyles.labelSmall.copyWith(
                                                                                  fontWeight: FontWeight.w600,
                                                                                  color: AppColors.black,
                                                                                ),
                                                                                maxLines: 2,
                                                                                overflow: TextOverflow.ellipsis,
                                                                                textAlign: TextAlign.center,
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  );
                                                                }).toList(),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  }),
                                                  Consumer<
                                                      CooperateEqubsProvider>(
                                                    builder:
                                                        (context, coopProv, _) {
                                                      if (!coopProv.isLoading &&
                                                          coopProv.cooperates
                                                              .isEmpty &&
                                                          coopProv.error ==
                                                              null) {
                                                        WidgetsBinding.instance
                                                            .addPostFrameCallback(
                                                                (_) {
                                                          coopProv
                                                              .fetchCooperates();
                                                        });
                                                      }

                                                      if (coopProv.isLoading) {
                                                        return const SizedBox
                                                            .shrink();
                                                      }

                                                      if (coopProv.error !=
                                                          null) {
                                                        if (coopProv.error ==
                                                            'Token is not valid') {
                                                          WidgetsBinding
                                                              .instance
                                                              .addPostFrameCallback(
                                                                  (_) {
                                                            Navigator.of(
                                                                    context)
                                                                .pushAndRemoveUntil(
                                                              MaterialPageRoute(
                                                                  builder: (_) =>
                                                                      LoginScreenWithPin(
                                                                          phoneNumber:
                                                                              '')),
                                                              (route) => false,
                                                            );
                                                          });
                                                        }
                                                        return const SizedBox
                                                            .shrink();
                                                      }

                                                      final List<Cooperate>
                                                          items =
                                                          coopProv.cooperates;
                                                      if (items.isEmpty) {
                                                        return const SizedBox
                                                            .shrink();
                                                      }

                                                      return Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    top: 16.h,
                                                                    bottom:
                                                                        10.h),
                                                            child: Center(
                                                              child: Text(
                                                                AppKeys
                                                                    .cooperateEqubsTitle
                                                                    .tr(context),
                                                                style: AppTextStyles
                                                                    .sectionTitle
                                                                    .copyWith(
                                                                  color: AppColors
                                                                      .richDeepGreen,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          LayoutBuilder(
                                                            builder: (context,
                                                                constraints) {
                                                              const crossAxisCount =
                                                                  3;
                                                              final spacing =
                                                                  8.w;
                                                              final itemWidth = (constraints
                                                                          .maxWidth -
                                                                      spacing *
                                                                          (crossAxisCount -
                                                                              1)) /
                                                                  crossAxisCount;
                                                              return Align(
                                                                alignment: Alignment
                                                                    .centerLeft,
                                                                child: Wrap(
                                                                  alignment:
                                                                      WrapAlignment
                                                                          .start,
                                                                  spacing:
                                                                      spacing,
                                                                  runSpacing:
                                                                      8.h,
                                                                  children:
                                                                      items.map(
                                                                          (item) {
                                                                    final networkUrl = (item.imageIcon !=
                                                                                null &&
                                                                            item.imageIcon!.isNotEmpty)
                                                                        ? '${mediaUrl}images/cooperate/${item.imageIcon}'
                                                                        : null;
                                                                    return SizedBox(
                                                                      width:
                                                                          itemWidth,
                                                                      child:
                                                                          AspectRatio(
                                                                        aspectRatio:
                                                                            0.95,
                                                                        child:
                                                                            GestureDetector(
                                                                          onTap:
                                                                              () async {
                                                                            final TextEditingController
                                                                                codeController =
                                                                                TextEditingController(text: item.code ?? '');
                                                                            final formKey =
                                                                                GlobalKey<FormState>();

                                                                            await showDialog(
                                                                              context: context,
                                                                              barrierDismissible: false,
                                                                              builder: (ctx) {
                                                                                bool isSubmitting = false;
                                                                                return StatefulBuilder(
                                                                                  builder: (context, setLocalState) {
                                                                                    return Dialog(
                                                                                      shape: RoundedRectangleBorder(
                                                                                        borderRadius: BorderRadius.circular(18),
                                                                                      ),
                                                                                      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
                                                                                      child: Padding(
                                                                                        padding: const EdgeInsets.all(24.0),
                                                                                        child: Column(
                                                                                          mainAxisSize: MainAxisSize.min,
                                                                                          children: [
                                                                                            const Icon(
                                                                                              Icons.lock_open_rounded,
                                                                                              size: 50,
                                                                                              color: AppColors.primary,
                                                                                            ),
                                                                                            const SizedBox(height: 18),
                                                                                            Text(
                                                                                              AppKeys.enterCodeTitle.tr(context),
                                                                                              style: AppTextStyles.dialogTitle.copyWith(
                                                                                                fontWeight: FontWeight.w700,
                                                                                                color: AppColors.vibrantGreen,
                                                                                              ),
                                                                                            ),
                                                                                            const SizedBox(height: 18),
                                                                                            Form(
                                                                                              key: formKey,
                                                                                              child: TextFormField(
                                                                                                controller: codeController,
                                                                                                decoration: InputDecoration(
                                                                                                  labelText: AppKeys.codeLabel.tr(context),
                                                                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                                                                  prefixIcon: const Icon(Icons.vpn_key, color: Colors.deepPurple),
                                                                                                ),
                                                                                                textInputAction: TextInputAction.done,
                                                                                                validator: (val) => (val == null || val.trim().isEmpty) ? AppKeys.codeRequired.tr(context) : null,
                                                                                              ),
                                                                                            ),
                                                                                            const SizedBox(height: 22),
                                                                                            Row(
                                                                                              children: [
                                                                                                Expanded(
                                                                                                  child: TextButton(
                                                                                                    onPressed: isSubmitting
                                                                                                        ? null
                                                                                                        : () {
                                                                                                            Navigator.pop(ctx);
                                                                                                          },
                                                                                                    style: TextButton.styleFrom(
                                                                                                      foregroundColor: Colors.grey[700],
                                                                                                      textStyle: AppTextStyles.buttonMedium,
                                                                                                    ),
                                                                                                    child: Text(AppKeys.cancel.tr(context)),
                                                                                                  ),
                                                                                                ),
                                                                                                const SizedBox(width: 12),
                                                                                                Expanded(
                                                                                                  child: ElevatedButton(
                                                                                                    style: ElevatedButton.styleFrom(
                                                                                                      backgroundColor: AppColors.primary,
                                                                                                      shadowColor: Colors.greenAccent,
                                                                                                      shape: RoundedRectangleBorder(
                                                                                                        borderRadius: BorderRadius.circular(10),
                                                                                                      ),
                                                                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                                                                    ),
                                                                                                    onPressed: isSubmitting
                                                                                                        ? null
                                                                                                        : () async {
                                                                                                            if (!(formKey.currentState?.validate() ?? false)) return;

                                                                                                            final token = await SecureStorageHelper.getAccessToken() ?? '';
                                                                                                            if (token.isEmpty) {
                                                                                                              await showDialog(
                                                                                                                context: context,
                                                                                                                builder: (dialogCtx) => AlertDialog(
                                                                                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                                                                  backgroundColor: Colors.red[50],
                                                                                                                  title: Row(
                                                                                                                    children: [
                                                                                                                      const Icon(Icons.error_outline, color: Colors.red, size: 28),
                                                                                                                      const SizedBox(width: 6),
                                                                                                                      Text(AppKeys.notAuthorizedTitle.tr(dialogCtx)),
                                                                                                                    ],
                                                                                                                  ),
                                                                                                                  content: Text(AppKeys.loginToContinue.tr(dialogCtx)),
                                                                                                                  actions: [
                                                                                                                    TextButton(
                                                                                                                      onPressed: () {
                                                                                                                        Navigator.pop(dialogCtx);
                                                                                                                      },
                                                                                                                      child: Text(AppKeys.ok.tr(dialogCtx)),
                                                                                                                    ),
                                                                                                                  ],
                                                                                                                ),
                                                                                                              );
                                                                                                              return;
                                                                                                            }

                                                                                                            setLocalState(() => isSubmitting = true);
                                                                                                            try {
                                                                                                              final dio = Dio(
                                                                                                                BaseOptions(
                                                                                                                  connectTimeout: const Duration(seconds: 12),
                                                                                                                  receiveTimeout: const Duration(seconds: 12),
                                                                                                                  headers: {
                                                                                                                    'Authorization': 'Bearer $token',
                                                                                                                    'Content-Type': 'application/json',
                                                                                                                  },
                                                                                                                ),
                                                                                                              );

                                                                                                              final response = await dio.post(
                                                                                                                validateCooperateUrl,
                                                                                                                data: {
                                                                                                                  'id': item.id,
                                                                                                                  'code': codeController.text.trim(),
                                                                                                                },
                                                                                                              );

                                                                                                              final dynamic data = response.data;
                                                                                                              final bool ok = (response.statusCode == 200 || response.statusCode == 201) && (data is Map && ((data['status'] == 'success') || (data['success'] == true)));

                                                                                                              Navigator.pop(ctx);

                                                                                                              if (ok) {
                                                                                                                Navigator.push(
                                                                                                                  context,
                                                                                                                  MaterialPageRoute(
                                                                                                                    builder: (_) => CooperateListScreen(
                                                                                                                      title: item.name ?? 'Equbs',
                                                                                                                      equbs: item.equbs ?? const [],
                                                                                                                    ),
                                                                                                                  ),
                                                                                                                );
                                                                                                              } else {
                                                                                                                final String errorMsg = (data is Map && data['message'] is String) ? data['message'] as String : AppKeys.validationFailedMessage.tr(context);
                                                                                                                await showDialog(
                                                                                                                  context: context,
                                                                                                                  builder: (dialogCtx) => AlertDialog(
                                                                                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                                                                    backgroundColor: Colors.red[50],
                                                                                                                    title: Row(
                                                                                                                      children: [
                                                                                                                        const Icon(Icons.clear_rounded, color: Colors.red, size: 28),
                                                                                                                        const SizedBox(width: 6),
                                                                                                                        Text(AppKeys.failedTitle.tr(dialogCtx)),
                                                                                                                      ],
                                                                                                                    ),
                                                                                                                    content: Text(errorMsg, style: AppTextStyles.bodyLarge),
                                                                                                                    actions: [
                                                                                                                      TextButton(
                                                                                                                        onPressed: () {
                                                                                                                          Navigator.pop(dialogCtx);
                                                                                                                        },
                                                                                                                        child: Text(AppKeys.ok.tr(dialogCtx)),
                                                                                                                      ),
                                                                                                                    ],
                                                                                                                  ),
                                                                                                                );
                                                                                                              }
                                                                                                            } on DioError catch (e) {
                                                                                                              Navigator.pop(ctx);
                                                                                                              String message = AppKeys.genericErrorMessage.tr(context);
                                                                                                              if (e.type == DioErrorType.connectionTimeout || e.type == DioErrorType.receiveTimeout) {
                                                                                                                message = AppKeys.timeoutErrorMessage.tr(context);
                                                                                                              } else if (e.response != null) {
                                                                                                                final data = e.response?.data;
                                                                                                                if (data is Map && data['message'] is String) {
                                                                                                                  message = data['message'] as String;
                                                                                                                } else if (e.response?.statusCode == 401) {
                                                                                                                  message = AppKeys.sessionExpiredMessage.tr(context);
                                                                                                                }
                                                                                                              }
                                                                                                              await showDialog(
                                                                                                                context: context,
                                                                                                                builder: (dialogCtx) => AlertDialog(
                                                                                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                                                                  backgroundColor: Colors.red[50],
                                                                                                                  title: Row(
                                                                                                                    children: [
                                                                                                                      const Icon(Icons.error_outline, color: Colors.red, size: 28),
                                                                                                                      const SizedBox(width: 6),
                                                                                                                      Text(AppKeys.errorTitle.tr(dialogCtx)),
                                                                                                                    ],
                                                                                                                  ),
                                                                                                                  content: Text(message, style: AppTextStyles.bodyLarge),
                                                                                                                  actions: [
                                                                                                                    TextButton(
                                                                                                                      onPressed: () => Navigator.pop(dialogCtx),
                                                                                                                      child: Text(AppKeys.ok.tr(dialogCtx)),
                                                                                                                    ),
                                                                                                                  ],
                                                                                                                ),
                                                                                                              );
                                                                                                            } catch (e) {
                                                                                                              Navigator.pop(ctx);
                                                                                                              await showDialog(
                                                                                                                context: context,
                                                                                                                builder: (dialogCtx) => AlertDialog(
                                                                                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                                                                  backgroundColor: Colors.red[50],
                                                                                                                  title: Row(
                                                                                                                    children: [
                                                                                                                      const Icon(Icons.error_outline, color: Colors.red, size: 28),
                                                                                                                      const SizedBox(width: 6),
                                                                                                                      Text(AppKeys.errorTitle.tr(dialogCtx)),
                                                                                                                    ],
                                                                                                                  ),
                                                                                                                  content: Text('${AppKeys.exceptionErrorPrefix.tr(dialogCtx)}$e', style: AppTextStyles.bodyLarge),
                                                                                                                  actions: [
                                                                                                                    TextButton(
                                                                                                                      onPressed: () => Navigator.pop(dialogCtx),
                                                                                                                      child: Text(AppKeys.ok.tr(dialogCtx)),
                                                                                                                    ),
                                                                                                                  ],
                                                                                                                ),
                                                                                                              );
                                                                                                            } finally {
                                                                                                              if (mounted) {
                                                                                                                setLocalState(() => isSubmitting = false);
                                                                                                              }
                                                                                                            }
                                                                                                          },
                                                                                                    child: isSubmitting
                                                                                                        ? const SizedBox(
                                                                                                            height: 20,
                                                                                                            width: 20,
                                                                                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                                                                          )
                                                                                                        : Text(AppKeys.join.tr(context), style: AppTextStyles.onPrimaryBold.copyWith(fontWeight: FontWeight.w700)),
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  },
                                                                                );
                                                                              },
                                                                            );
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: Colors.white,
                                                                              borderRadius: BorderRadius.circular(12.r),
                                                                              border: Border.all(color: Colors.grey.shade200),
                                                                            ),
                                                                            padding: EdgeInsets.fromLTRB(
                                                                                8.w,
                                                                                10.h,
                                                                                8.w,
                                                                                8.h),
                                                                            child:
                                                                                Column(
                                                                              children: [
                                                                                Expanded(
                                                                                  child: Center(
                                                                                    child: _HomeFallbackIcon(
                                                                                      networkUrl: networkUrl,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Text(
                                                                                  item.name ?? '-',
                                                                                  textAlign: TextAlign.center,
                                                                                  maxLines: 2,
                                                                                  overflow: TextOverflow.ellipsis,
                                                                                  style: AppTextStyles.labelSmall.copyWith(
                                                                                    fontWeight: FontWeight.w600,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }).toList(),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    SliverToBoxAdapter(
                                      child: SizedBox(
                                        height: 200.h
                                      ),
                                    ),
                                  ],
                                )),
                ),
                bottomNavigationBar: widget.embedInShell
                    ? null
                    : Consumer<JoinedEqubsStatusProvider>(
                        builder: (context, joinStatus, _) {
                          final currentIndex = newEqubTabIndex(context);
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
              ),
            ),
          );
        },
      ),
    );
  }

  String getEqubIcon(String? name) {
    switch (name) {
      case "Car Equb":
        return "assets/care.png";
      case "House Equb":
        return "assets/home.png";
      default:
        return "assets/equb.png";
    }
  }
}

class _HomeFallbackIcon extends StatelessWidget {
  final String? networkUrl;

  const _HomeFallbackIcon({this.networkUrl});

  static const String _fallbackAsset = 'assets/splash.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.h,
      width: 40.w,
      child: (networkUrl != null && networkUrl!.isNotEmpty)
          ? Image.network(
              networkUrl!,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Image.asset(
                _fallbackAsset,
                fit: BoxFit.contain,
              ),
            )
          : Image.asset(
              _fallbackAsset,
              fit: BoxFit.contain,
            ),
    );
  }
}

class StyledTab extends StatelessWidget {
  final String text;
  final bool isSelected;

  const StyledTab({
    super.key,
    required this.text,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28.h,
      width: 93.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            // isSelected ? Colors.white : const Color.fromRGBO(209, 243, 203, 1),
            isSelected
                ? Colors.white
                : const Color.fromARGB(255, 219, 225, 217),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown, // Ensures the text scales down but not up.
        child: Text(
          textScaleFactor: 1.0,
          text == "Daily"
              ? AppKeys.daily.tr(context)
              : text == "Weekly"
                  ? AppKeys.weekly.tr(context)
                  : AppKeys.monthly.tr(context),
          style: AppTextStyles.cardTitle.copyWith(
            color: const Color.fromARGB(255, 10, 69, 1),
          ),
        ),
      ),
    );
  }
}

class CardItem extends StatelessWidget {
  final int index;
  final String cardIndex;
  final IconData imagePath;
  final int selectedIndex;

  const CardItem(this.index, this.cardIndex, this.imagePath, this.selectedIndex,
      {super.key});

  String getCategory(int selected, BuildContext context) {
    switch (selected) {
      case 0:
        return AppKeys.daily.tr(context);
      case 1:
        return AppKeys.weekly.tr(context);
      case 2:
        return AppKeys.daily.tr(context);
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.25),
                offset: Offset(2, 0), // Shadow on the right
                blurRadius: 4.0,
              ),
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.25),
                offset: Offset(-2, 0), // Shadow on the left
                blurRadius: 4.0,
              ),
            ],
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(4.0),
              bottomRight: Radius.circular(4.0),
            ),
          ),
          child: GestureDetector(
            onTap: () {
              switch (index) {
                case 0:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EqubCategoryScreen(
                        id: "",
                        type: getCategory(selectedIndex, context),
                      ),
                    ),
                  );
                  break;
              }
            },
            child: Card(
              color: const Color.fromARGB(255, 255, 255, 255),
              shadowColor: const Color.fromRGBO(0, 0, 0, 0.25),
              elevation: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    imagePath,
                    color: Colors.black,
                    size: 37,
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        textScaleFactor: 1.0,
                        cardIndex,
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final BannerModel banner;
  const _BannerCard({required this.banner});
  String _fixBannerUrl(String url) {
    if (url.contains('/banner/')) return url;

    if (url.contains('/images/')) {
      return url.replaceFirst('/images/', '/images/banner/');
    }

    return url;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160.h,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _fixBannerUrl(banner.imageUrl),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.fitHeight,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image,
                    size: 40, color: Colors.grey),
              ),
            ),

            ///
            // Gradient overlay
            // Container(
            //   decoration:  BoxDecoration(
            //     gradient: LinearGradient(
            //       colors: [AppColors.primary.withOpacity(0.5), AppColors.secondary.withOpacity(0.3)],
            //       begin: Alignment.topLeft,
            //       end: Alignment.bottomRight,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

Color getEqubTypeColor(String? name) {
  if (name == null) return AppColors.lightGray.withOpacity(0.4);
  switch (name.toLowerCase()) {
    case 'all':
      return AppColors.lightGray.withOpacity(0.4);
    case 'daily':
      return AppColors.blue.withOpacity(0.22);
    case 'weekly':
      return AppColors.orange.withOpacity(0.22);
    case 'monthly':
      return AppColors.green.withOpacity(0.22);
    case 'car equb':
      return AppColors.purple.withOpacity(0.15);
    case 'house equb':
      return AppColors.teal.withOpacity(0.15);
    default:
      return AppColors.primary.withOpacity(0.13);
  }
}
