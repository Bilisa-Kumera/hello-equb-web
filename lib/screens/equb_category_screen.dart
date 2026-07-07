// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:helloequb/models/equb_model.dart';
import 'package:helloequb/screens/payment_screen.dart';
import 'package:helloequb/screens/transaction_history.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/core/api_service_elper.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/main.dart';
import 'package:helloequb/models/ekub_category_model.dart';
import 'package:helloequb/models/registered_ekubs.dart';
import 'package:helloequb/screens/home_screen.dart';
import 'package:helloequb/screens/join_ekub_detail.dart';
import 'package:helloequb/screens/my_other_ekubs.dart';
import 'package:helloequb/screens/notification_screen.dart';
import 'package:helloequb/screens/profile_screen.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/completed_ekub_dialog.dart';
import 'package:helloequb/utils/custom_bottom_nav.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:helloequb/utils/lang_constants.dart';

import '../utils/secure_storage.dart';
import 'allequb_payment.dart';

class EqubCategoryScreen extends StatefulWidget {
  final String type, id;
  const EqubCategoryScreen({super.key, required this.type, required this.id});

  @override
  State<EqubCategoryScreen> createState() => _EqubCategoryScreenState();
}

class _EqubCategoryScreenState extends State<EqubCategoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService apiService = ApiService();
  List<Equbs> ekubs = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  bool isLoading = false;
  int pageLimit = 30;
  int ekubsLength = 10;
  bool hasMore = true;
  Future<void> loadMoreEqubs() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    List<Equbs> newEqubs = await getRunningEkubs(
      widget.id,
      searchController.text,
      currentPage,
      pageLimit,
    );

    setState(() {
      ekubs.addAll(newEqubs);

      // Check if more items need to be loaded
      hasMore = newEqubs.length == pageLimit; // True if page was fully filled

      currentPage++; // Move to next page
      isLoading = false;
    });
  }

  Future<List<Equbs>> getRunningEkubs(
      String id, String searchQuery, int page, int limit) async {
    List<Equbs> filteredEkubs = [];
    String accessToken = await SecureStorageHelper.getAccessToken() ?? '';
    try {
      final data = await apiService.readAll(
          "$ekubsUrl?_page=$page&_limit=$limit&equbCategory=$id&_search=$searchQuery",
          bearerToken: accessToken);

      if (data != null) {
        List<dynamic> equbsData = data['data']['equbs'];
        ekubs = equbsData.map((json) => Equbs.fromJson(json)).toList();
        setState(() {});
      }
    } catch (e, s) {}
    return filteredEkubs;
  }

  bool _isLoading = false;
  bool isSearch = false;

  void showSpinnerForOneMinute() {
    setState(() {
      _isLoading = true;
      isSearch = true;
    });

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          isSearch = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    showSpinnerForOneMinute();
    getRunningEkubs(widget.id, '', 1, 10);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  final List<Map<String, dynamic>> data = [
    {
      'title': 'Suzuki Swift 2022',
      'amount': 300000,
      'cycle': 6,
      'person': 10,
      'buttonLabel': 'Join Now',
      'imagePath': 'assets/car2.png',
    },
    {
      'title': 'Toyota Yaris 2021',
      'amount': 300000,
      'cycle': 6,
      'person': 10,
      'buttonLabel': 'Join Now',
      'imagePath': 'assets/car2.png',
    },
    {
      'title': 'Yaris Belta 2012',
      'amount': 300000,
      'cycle': 6,
      'person': 10,
      'buttonLabel': 'Join Now',
      'imagePath': 'assets/car3.png',
    },
  ];
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final DataController dataController = DataController();

  Future<List<EqubCategorys>?> loadEkubCategories() async {
    List<dynamic>? jsonList =
        dataController.retrieveData<List<dynamic>>('ekubCategories');

    if (jsonList != null) {
      return jsonList
          .map((json) => EqubCategorys.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return null; // Return null if no data is found
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.black, // Transparent background
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 20),
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      NetworkImage('${mediaUrl}images/avatar/${widget.type}'),
                ),
              ),
              title: Padding(
                padding: const EdgeInsets.only(top: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      textScaleFactor: 1.0,
                      dataController.retrieveData<String>('fullName') ?? '',
                      style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          fontFamily: 'Poppins'),
                    ),
                    Text(
                      textScaleFactor: 1.0,
                      AppKeys.welcomeBack.tr(context),
                      style: TextStyle(
                          color: AppColors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w300,
                          fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.notifications),
                    color: AppColors.white,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ));
                    },
                  ),
                ),
              ],
              pinned: true,
              floating: false,
              expandedHeight: 176, // Adjust as needed
              flexibleSpace: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                child: FlexibleSpaceBar(
                  background: Column(
                    children: [
                      SizedBox(height: 40.h),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 18.0, right: 18, top: 88),
                        child: SizedBox(
                          height: 40,
                          child: TextFormField(
                            controller: searchController,
                            decoration: InputDecoration(
                              filled: true,
                              hintText:
                                  AppKeys.whatAreYouLookingFor.tr(context),
                              hintStyle: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: AppColors.mediumGrayCool,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    currentPage = 1;
                                    ekubs.clear();
                                    loadMoreEqubs();
                                  });
                                },
                                icon: const Icon(
                                  Icons.search_sharp,
                                  size: 19,
                                  color: AppColors.mediumLightGray,
                                ),
                              ),
                              fillColor: AppColors.lightPinkGray,
                              enabledBorder: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0)),
                                borderSide: BorderSide(
                                  color: AppColors.lightWarmGray,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0)),
                                borderSide: BorderSide(
                                  color: AppColors.black,
                                  width: 2.0,
                                ),
                              ),
                              border: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(13)),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isEmpty) {
                                getRunningEkubs(widget.id, '', 1, 10);
                              } else {
                                getRunningEkubs(widget.id, value, 1, 10);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverFillRemaining(
              child: SingleChildScrollView(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.only(top: 28.0),
                          child: Center(
                            child: SpinKitFadingCircle(
                              color: AppColors.black,
                              size: 50.0,
                            ),
                          ),
                        )
                      : ekubs.isEmpty
                          ? Center(
                              child: Padding(
                              padding: const EdgeInsets.only(top: 28.0),
                              child: Text(AppKeys.noData.tr(context)),
                            ))
                          : Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 28.0, top: 20),
                                      child: Text(
                                        textScaleFactor: 1.0,
                                        ekubs.first.equbCategory.name,
                                        style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                widget.id ==
                                        dataController.retrieveData('order4')
                                    ? ekubs.isEmpty
                                        ? Text(AppKeys.noData.tr(context))
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            controller: _scrollController,
                                            // physics:
                                            //     const NeverScrollableScrollPhysics(),
                                            itemCount: ekubs.length +
                                                (hasMore
                                                    ? 1
                                                    : 0), // Add an extra item if there are more to load
                                            itemBuilder: (context, index) {
                                              // Check if this is the last item and if there are more items to load
                                              if (index == ekubs.length &&
                                                  hasMore) {
                                                return Padding(
                                                  padding: const EdgeInsets.all(
                                                      16.0),
                                                  child: ekubs.length >
                                                          ekubsLength
                                                      ? const SizedBox
                                                          .shrink() // Hide button when all items are loaded
                                                      : OutlinedButton(
                                                          onPressed: () {
                                                            if (!isLoading) {
                                                              loadMoreEqubs(); // Call loadMoreEqubs to fetch more data
                                                              setState(() {
                                                                ekubsLength +=
                                                                    10; // Update the ekubsLength
                                                              });
                                                            }
                                                          },
                                                          style: OutlinedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                AppColors.black,
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        10,
                                                                    horizontal:
                                                                        20),
                                                          ),
                                                          child: Text(
                                                            textScaleFactor:
                                                                1.0,
                                                            isLoading
                                                                ? AppKeys
                                                                    .loading
                                                                    .tr(context)
                                                                : AppKeys
                                                                    .loadMore
                                                                    .tr(context),
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: AppColors
                                                                  .white,
                                                            ),
                                                          ),
                                                        ),
                                                );
                                              }

                                              // Build each ekub item
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 5.0,
                                                    left: 5,
                                                    top: 10),
                                                child: InkWell(
                                                  onTap: () {
                                                    if (ekubs[index].status ==
                                                        "completed") {
                                                      ModernDialog
                                                          .showEqubCompletedDialog(
                                                              context);
                                                    }
                                                  },
                                                  child: Card(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            const BorderRadius
                                                                .all(
                                                                Radius.circular(
                                                                    8)),
                                                        gradient:
                                                            LinearGradient(
                                                          begin:
                                                              Alignment.center,
                                                          end: Alignment
                                                              .centerLeft,
                                                          colors: ekubs[index]
                                                                      .status ==
                                                                  "completed"
                                                              ? [
                                                                  const Color
                                                                      .fromRGBO(
                                                                      158,
                                                                      158,
                                                                      157,
                                                                      1), // Start color
                                                                  const Color
                                                                      .fromRGBO(
                                                                      86,
                                                                      88,
                                                                      86,
                                                                      1), // End color
                                                                ]
                                                              : [
                                                                  // const Color
                                                                  //     .fromRGBO(
                                                                  //     97,
                                                                  //     180,
                                                                  //     13,
                                                                  //     1), // Start color
                                                                  // const Color
                                                                  //     .fromRGBO(
                                                                  //     23,
                                                                  //     133,
                                                                  //     4,
                                                                  //     1), // End color
                                                                  const Color
                                                                      .fromRGBO(
                                                                      118,
                                                                      166,
                                                                      70,
                                                                      1),
                                                                  const Color
                                                                      .fromRGBO(
                                                                      10,
                                                                      63,
                                                                      1,
                                                                      1),
                                                                ],
                                                        ),
                                                      ),
                                                      height: 106,
                                                      width: 305,
                                                      padding: const EdgeInsets
                                                          .only(),
                                                      child: Stack(
                                                        children: [
                                                          // Positioned(
                                                          //   left: 0,
                                                          //   top: 0,
                                                          //   bottom: 50,
                                                          //   child: Padding(
                                                          //     padding:
                                                          //         const EdgeInsets
                                                          //             .only(
                                                          //             left:
                                                          //                 8.0),
                                                          //     child: Row(
                                                          //       mainAxisAlignment:
                                                          //           MainAxisAlignment
                                                          //               .center,
                                                          //       children: [
                                                          //         const Icon(
                                                          //           Icons
                                                          //               .people_alt_outlined,
                                                          //           size: 18,
                                                          //           color: AppColors
                                                          //               .white,
                                                          //         ),
                                                          //         Padding(
                                                          //           padding: const EdgeInsets
                                                          //               .only(
                                                          //               left:
                                                          //                   5.0),
                                                          //           child: Text(
                                                          //             textScaleFactor:
                                                          //                 1.0,
                                                          //             ekubs[index]
                                                          //                     .equbers
                                                          //                     ?.length
                                                          //                     .toString() ??
                                                          //                 '0',
                                                          //             style:
                                                          //                 const TextStyle(
                                                          //               fontFamily:
                                                          //                   'Poppins',
                                                          //               fontWeight:
                                                          //                   FontWeight.w400,
                                                          //               fontSize:
                                                          //                   12,
                                                          //               color: AppColors
                                                          //                   .white,
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
                                                                  const EdgeInsets
                                                                      .only(
                                                                      right:
                                                                          8.0),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  const Icon(
                                                                    Icons
                                                                        .loop_rounded,
                                                                    size: 18,
                                                                    color: AppColors
                                                                        .white,
                                                                  ),
                                                                  Text(
                                                                    textScaleFactor:
                                                                        1.0,
                                                                    ekubs[index]
                                                                        .numberOfEqubers
                                                                        .toString(),
                                                                    style:
                                                                        const TextStyle(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w400,
                                                                      fontSize:
                                                                          12,
                                                                      color: AppColors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          Center(
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Text(
                                                                  textScaleFactor:
                                                                      1.0,
                                                                  ekubs[index]
                                                                      .name,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontFamily:
                                                                        'Poppins',
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: AppColors
                                                                        .white,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: 120.w,
                                                                  child:
                                                                      FittedBox(
                                                                    fit: BoxFit
                                                                        .scaleDown,
                                                                    child: Text(
                                                                      textScaleFactor:
                                                                          1.0,
                                                                      numberFormat.format(ekubs[index]
                                                                              .ekubAmount *
                                                                          ekubs[index]
                                                                              .numberOfEqubers),
                                                                      style:
                                                                          TextStyle(
                                                                        fontFamily:
                                                                            'Poppins',
                                                                        fontSize:
                                                                            28.sp,
                                                                        fontWeight:
                                                                            FontWeight.w900,
                                                                        color: AppColors
                                                                            .white,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: 20,
                                                                  child: ekubs[index]
                                                                              .status ==
                                                                          "completed"
                                                                      ? const SizedBox
                                                                          .shrink()
                                                                      : OutlinedButton(
                                                                          onPressed:
                                                                              () {
                                                                            Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(
                                                                                builder: (context) => EqubJoinDetail(
                                                                                  equb: EqubModel(isActive: false),
                                                                                  equbType: widget.type,
                                                                                ),
                                                                              ),
                                                                            );
                                                                          },
                                                                          style:
                                                                              const ButtonStyle(backgroundColor: WidgetStatePropertyAll(AppColors.white)),
                                                                          child:
                                                                              Text(
                                                                            textScaleFactor:
                                                                                1.0,
                                                                            AppKeys.join.tr(context),
                                                                            style:
                                                                                const TextStyle(color: AppColors.black),
                                                                          ),
                                                                        ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        top: 40,
                                                                        right:
                                                                            20),
                                                                child:
                                                                    ClipRRect(
                                                                  borderRadius:
                                                                      const BorderRadius
                                                                          .only(
                                                                    topLeft: Radius
                                                                        .circular(
                                                                            9),
                                                                    bottomLeft:
                                                                        Radius.circular(
                                                                            9), // Only the top-left corner is rounded
                                                                    // Only the top-left corner is rounded
                                                                  ),
                                                                  child:
                                                                      Container(
                                                                    decoration:
                                                                        const BoxDecoration(
                                                                      color: AppColors
                                                                          .transparent, // Set a transparent background color to avoid unwanted borders
                                                                    ),
                                                                    child: Image
                                                                        .asset(
                                                                      'assets/car4.png',
                                                                      height:
                                                                          42,
                                                                      width: 72,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        top: 42,
                                                                        left:
                                                                            78),
                                                                child:
                                                                    ClipRRect(
                                                                  borderRadius:
                                                                      const BorderRadius
                                                                          .only(
                                                                    topRight: Radius
                                                                        .circular(
                                                                            9),
                                                                    bottomRight:
                                                                        Radius.circular(
                                                                            9), // Only the top-left corner is rounded
                                                                    // Only the top-left corner is rounded
                                                                  ),
                                                                  child:
                                                                      Container(
                                                                    decoration:
                                                                        const BoxDecoration(
                                                                      color: AppColors
                                                                          .transparent, // Set a transparent background color to avoid unwanted borders
                                                                    ),
                                                                    child: Image
                                                                        .asset(
                                                                      'assets/car2.png',
                                                                      height:
                                                                          42,
                                                                      width: 72,
                                                                      fit: BoxFit
                                                                          .cover,
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
                                                ),
                                              );
                                            },
                                          )
                                    : widget.id ==
                                            dataController
                                                .retrieveData('order3')
                                        ? ekubs.isEmpty
                                            ? const Text(
                                                'No search results found')
                                            : Container(
                                                color: AppColors.white,
                                                // height: 500,
                                                child: ListView.builder(
                                                    shrinkWrap: true,
                                                    itemCount: data.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final item = data[index];
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 18.0,
                                                                right: 18),
                                                        child: InkWell(
                                                          onTap: () {
                                                            if (ekubs[index]
                                                                    .status ==
                                                                "completed") {
                                                              ModernDialog
                                                                  .showEqubCompletedDialog(
                                                                      context);
                                                            }
                                                          },
                                                          child: Card(
                                                            color:
                                                                AppColors.white,
                                                            elevation: 3,
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                              child: Row(
                                                                children: [
                                                                  Expanded(
                                                                    flex: 3,
                                                                    child:
                                                                        Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Text(
                                                                          textScaleFactor:
                                                                              1.0,
                                                                          item[
                                                                              'title'],
                                                                          style: const TextStyle(
                                                                              fontFamily: 'Poppins',
                                                                              fontWeight: FontWeight.w700,
                                                                              fontSize: 14,
                                                                              color: AppColors.neutralGray),
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              7,
                                                                        ),
                                                                        Text(
                                                                          textScaleFactor:
                                                                              1.0,
                                                                          "${item['amount']}/",
                                                                          style: const TextStyle(
                                                                              color: AppColors.vibrantGreen,
                                                                              fontFamily: 'Poppins',
                                                                              fontSize: 11,
                                                                              fontWeight: FontWeight.w700),
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              7,
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            const Icon(
                                                                              Icons.loop,
                                                                              color: AppColors.vibrantGreen,
                                                                              size: 12,
                                                                            ),
                                                                            const SizedBox(
                                                                              width: 12,
                                                                            ),
                                                                            Text(
                                                                              textScaleFactor: 1.0,
                                                                              "${item['cycle']}",
                                                                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.neutralGray),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              7,
                                                                        ),
                                                                        // Row(
                                                                        //   children: [
                                                                        //     const Icon(
                                                                        //       Icons.people_alt_outlined,
                                                                        //       color: AppColors.vibrantGreen,
                                                                        //       size: 12,
                                                                        //     ),
                                                                        //     const SizedBox(
                                                                        //       width: 10,
                                                                        //     ),
                                                                        //     Text(
                                                                        //       textScaleFactor: 1.0,
                                                                        //       "${item['person']}",
                                                                        //       style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.neutralGray),
                                                                        //     ),
                                                                        //   ],
                                                                        // ),
                                                                        const SizedBox(
                                                                            height:
                                                                                8.0),
                                                                        SizedBox(
                                                                          height:
                                                                              20,
                                                                          child:
                                                                              OutlinedButton(
                                                                            style:
                                                                                const ButtonStyle(backgroundColor: WidgetStatePropertyAll(AppColors.white)),
                                                                            onPressed:
                                                                                () {
                                                                              // Handle button press
                                                                              Navigator.push(
                                                                                  context,
                                                                                  MaterialPageRoute(
                                                                                      builder: (context) => EqubJoinDetail(
                                                                                            equb: EqubModel(isActive: false),
                                                                                            equbType: widget.type,
                                                                                          )));
                                                                            },
                                                                            child:
                                                                                Text(
                                                                              textScaleFactor: 1.0,
                                                                              item['buttonLabel'],
                                                                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.white),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    flex: 2,
                                                                    child: Image
                                                                        .network(
                                                                      item[
                                                                          'imagePath'],
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                              )
                                        : widget.id ==
                                                dataController
                                                    .retrieveData('order5')
                                            ? ekubs.isEmpty
                                                ? Text(
                                                    AppKeys.noData.tr(context))
                                                : ListView.builder(
                                                    shrinkWrap: true,
                                                    controller:
                                                        _scrollController,
                                                    // physics:
                                                    //     const NeverScrollableScrollPhysics(),
                                                    itemCount: ekubs.length +
                                                        (hasMore
                                                            ? 1
                                                            : 0), // Add an extra item if there are more to load
                                                    itemBuilder:
                                                        (context, index) {
                                                      // Check if this is the last item and if there are more items to load
                                                      if (index ==
                                                              ekubs.length &&
                                                          hasMore) {
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(16.0),
                                                          child: ekubs.length >
                                                                  ekubsLength
                                                              ? const SizedBox
                                                                  .shrink() // Hide button when all items are loaded
                                                              : OutlinedButton(
                                                                  onPressed:
                                                                      () {
                                                                    if (!isLoading) {
                                                                      loadMoreEqubs(); // Call loadMoreEqubs to fetch more data
                                                                      setState(
                                                                          () {
                                                                        ekubsLength +=
                                                                            10; // Update the ekubsLength
                                                                      });
                                                                    }
                                                                  },
                                                                  style: OutlinedButton
                                                                      .styleFrom(
                                                                    backgroundColor:
                                                                        AppColors
                                                                            .black,
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            10,
                                                                        horizontal:
                                                                            20),
                                                                  ),
                                                                  child: Text(
                                                                    textScaleFactor:
                                                                        1.0,
                                                                    isLoading
                                                                        ? AppKeys
                                                                            .loading
                                                                            .tr(
                                                                                context)
                                                                        : AppKeys
                                                                            .loadMore
                                                                            .tr(context),
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: AppColors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                ),
                                                        );
                                                      }

                                                      // Build each ekub item
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                right: 5.0,
                                                                left: 5,
                                                                top: 10),
                                                        child: InkWell(
                                                          onTap: () {
                                                            if (ekubs[index]
                                                                    .status ==
                                                                "completed") {
                                                              ModernDialog
                                                                  .showEqubCompletedDialog(
                                                                      context);
                                                            }
                                                          },
                                                          child: Card(
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    const BorderRadius
                                                                        .all(
                                                                        Radius.circular(
                                                                            8)),
                                                                gradient:
                                                                    LinearGradient(
                                                                  begin: Alignment
                                                                      .center,
                                                                  end: Alignment
                                                                      .centerLeft,
                                                                  colors: ekubs[index]
                                                                              .status ==
                                                                          "completed"
                                                                      ? [
                                                                          const Color
                                                                              .fromRGBO(
                                                                              158,
                                                                              158,
                                                                              157,
                                                                              1), // Start color
                                                                          const Color
                                                                              .fromRGBO(
                                                                              86,
                                                                              88,
                                                                              86,
                                                                              1), // End color
                                                                        ]
                                                                      : [
                                                                          // const Color
                                                                          //     .fromRGBO(
                                                                          //     97,
                                                                          //     180,
                                                                          //     13,
                                                                          //     1), // Start color
                                                                          // const Color
                                                                          //     .fromRGBO(
                                                                          //     23,
                                                                          //     133,
                                                                          //     4,
                                                                          //     1),
                                                                          // // End color
                                                                          const Color
                                                                              .fromARGB(
                                                                              255,
                                                                              31,
                                                                              45,
                                                                              17),
                                                                          const Color
                                                                              .fromRGBO(
                                                                              10,
                                                                              63,
                                                                              1,
                                                                              1),
                                                                        ],
                                                                ),
                                                              ),
                                                              height: 106,
                                                              width: 305,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(),
                                                              child: Stack(
                                                                children: [
                                                                  // Positioned(
                                                                  //   left: 0,
                                                                  //   top: 0,
                                                                  //   bottom: 50,
                                                                  //   child:
                                                                  //       Padding(
                                                                  //     padding: const EdgeInsets
                                                                  //         .only(
                                                                  //         left:
                                                                  //             8.0),
                                                                  //     child:
                                                                  //         Row(
                                                                  //       mainAxisAlignment:
                                                                  //           MainAxisAlignment.center,
                                                                  //       children: [
                                                                  //         const Icon(
                                                                  //           Icons.people_alt_outlined,
                                                                  //           size:
                                                                  //               18,
                                                                  //           color:
                                                                  //               AppColors.white,
                                                                  //         ),
                                                                  //         Padding(
                                                                  //           padding:
                                                                  //               const EdgeInsets.only(left: 5.0),
                                                                  //           child:
                                                                  //               Text(
                                                                  //             textScaleFactor: 1.0,
                                                                  //             ekubs[index].equbers?.length.toString() ?? '0',
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
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          right:
                                                                              8.0),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          const Icon(
                                                                            Icons.loop_rounded,
                                                                            size:
                                                                                18,
                                                                            color:
                                                                                AppColors.white,
                                                                          ),
                                                                          Text(
                                                                            textScaleFactor:
                                                                                1.0,
                                                                            ekubs[index].numberOfEqubers.toString(),
                                                                            style:
                                                                                const TextStyle(
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
                                                                    child:
                                                                        Column(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Text(
                                                                          textScaleFactor:
                                                                              1.0,
                                                                          ekubs[index]
                                                                              .name,
                                                                          style:
                                                                              const TextStyle(
                                                                            fontFamily:
                                                                                'Poppins',
                                                                            fontSize:
                                                                                16,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            color:
                                                                                AppColors.white,
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              120.w,
                                                                          child:
                                                                              FittedBox(
                                                                            fit:
                                                                                BoxFit.scaleDown,
                                                                            child:
                                                                                Text(
                                                                              textScaleFactor: 1.0,
                                                                              numberFormat.format(ekubs[index].ekubAmount * ekubs[index].numberOfEqubers),
                                                                              style: TextStyle(
                                                                                fontFamily: 'Poppins',
                                                                                fontSize: 28.sp,
                                                                                fontWeight: FontWeight.w900,
                                                                                color: AppColors.white,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              20,
                                                                          child: ekubs[index].status == "completed"
                                                                              ? const SizedBox.shrink()
                                                                              : OutlinedButton(
                                                                                  onPressed: () {
                                                                                    Navigator.push(
                                                                                      context,
                                                                                      MaterialPageRoute(
                                                                                        builder: (context) => EqubJoinDetail(
                                                                                          equb: EqubModel(isActive: false),
                                                                                          equbType: widget.type,
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  },
                                                                                  style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(AppColors.white)),
                                                                                  child: Text(
                                                                                    textScaleFactor: 1.0,
                                                                                    AppKeys.join.tr(context),
                                                                                    style: const TextStyle(color: AppColors.black),
                                                                                  ),
                                                                                ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            top:
                                                                                40,
                                                                            right:
                                                                                20),
                                                                        child:
                                                                            ClipRRect(
                                                                          borderRadius:
                                                                              const BorderRadius.only(
                                                                            topLeft:
                                                                                Radius.circular(9),
                                                                            bottomLeft:
                                                                                Radius.circular(9), // Only the top-left corner is rounded
                                                                            // Only the top-left corner is rounded
                                                                          ),
                                                                          child:
                                                                              Container(
                                                                            decoration:
                                                                                const BoxDecoration(
                                                                              color: AppColors.transparent, // Set a transparent background color to avoid unwanted borders
                                                                            ),
                                                                            child:
                                                                                Image.asset(
                                                                              'assets/home1.png',
                                                                              height: 42,
                                                                              width: 72,
                                                                              fit: BoxFit.cover,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            top:
                                                                                42,
                                                                            left:
                                                                                78),
                                                                        child:
                                                                            ClipRRect(
                                                                          borderRadius:
                                                                              const BorderRadius.only(
                                                                            topRight:
                                                                                Radius.circular(9),
                                                                            bottomRight:
                                                                                Radius.circular(9), // Only the top-left corner is rounded
                                                                            // Only the top-left corner is rounded
                                                                          ),
                                                                          child:
                                                                              Container(
                                                                            decoration:
                                                                                const BoxDecoration(
                                                                              color: AppColors.transparent, // Set a transparent background color to avoid unwanted borders
                                                                            ),
                                                                            child:
                                                                                Image.asset(
                                                                              'assets/home2.png',
                                                                              height: 42,
                                                                              width: 72,
                                                                              fit: BoxFit.cover,
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
                                                        ),
                                                      );
                                                    },
                                                  )
                                            : ekubs.isEmpty
                                                ? const Text(
                                                    'No search results found')
                                                : ListView.builder(
                                                    shrinkWrap: true,
                                                    controller:
                                                        _scrollController,
                                                    // physics:
                                                    //     const NeverScrollableScrollPhysics(),
                                                    itemCount: ekubs.length +
                                                        (hasMore
                                                            ? 1
                                                            : 0), // Add an extra item if there are more to load
                                                    itemBuilder:
                                                        (context, index) {
                                                      // Check if this is the last item and if there are more items to load
                                                      if (index ==
                                                              ekubs.length &&
                                                          hasMore) {
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(16.0),
                                                          child: ekubs.length >
                                                                  ekubsLength
                                                              ? const SizedBox
                                                                  .shrink() // Hide button when all items are loaded
                                                              : OutlinedButton(
                                                                  onPressed:
                                                                      () {
                                                                    if (!isLoading) {
                                                                      loadMoreEqubs(); // Call loadMoreEqubs to fetch more data
                                                                      setState(
                                                                          () {
                                                                        ekubsLength +=
                                                                            10; // Update the ekubsLength
                                                                      });
                                                                    }
                                                                  },
                                                                  style: OutlinedButton
                                                                      .styleFrom(
                                                                    backgroundColor:
                                                                        AppColors
                                                                            .white,
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            10,
                                                                        horizontal:
                                                                            20),
                                                                  ),
                                                                  child: Text(
                                                                    textScaleFactor:
                                                                        1.0,
                                                                    isLoading
                                                                        ? AppKeys
                                                                            .loading
                                                                            .tr(
                                                                                context)
                                                                        : AppKeys
                                                                            .loadMore
                                                                            .tr(context),
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: AppColors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                ),
                                                        );
                                                      }

                                                      // Build each ekub item
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                right: 5.0,
                                                                left: 5,
                                                                top: 10),
                                                        child: InkWell(
                                                          onTap: () {
                                                            if (ekubs[index]
                                                                    .status ==
                                                                "completed") {
                                                              ModernDialog
                                                                  .showEqubCompletedDialog(
                                                                      context);
                                                            }
                                                          },
                                                          child: Card(
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    const BorderRadius
                                                                        .all(
                                                                        Radius.circular(
                                                                            8)),
                                                                gradient:
                                                                    LinearGradient(
                                                                  begin: Alignment
                                                                      .center,
                                                                  end: Alignment
                                                                      .centerLeft,
                                                                  colors: ekubs[index]
                                                                              .status ==
                                                                          "completed"
                                                                      ? [
                                                                          const Color
                                                                              .fromRGBO(
                                                                              158,
                                                                              158,
                                                                              157,
                                                                              1), // Start color
                                                                          const Color
                                                                              .fromRGBO(
                                                                              86,
                                                                              88,
                                                                              86,
                                                                              1), // End color
                                                                        ]
                                                                      : [
                                                                          // const Color
                                                                          //     .fromRGBO(
                                                                          //     97,
                                                                          //     180,
                                                                          //     13,
                                                                          //     1), // Start color
                                                                          // const Color
                                                                          //     .fromRGBO(
                                                                          //     23,
                                                                          //     133,
                                                                          //     4,
                                                                          //     1), // End color
                                                                          const Color
                                                                              .fromARGB(
                                                                              255,
                                                                              28,
                                                                              41,
                                                                              16),
                                                                          const Color
                                                                              .fromRGBO(
                                                                              10,
                                                                              63,
                                                                              1,
                                                                              1),
                                                                        ],
                                                                ),
                                                              ),
                                                              height: 106,
                                                              width: 305,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 7.0,
                                                                      bottom:
                                                                          8),
                                                              child: Stack(
                                                                children: [
                                                                  // Positioned(
                                                                  //   left: 0,
                                                                  //   top: 0,
                                                                  //   bottom: 50,
                                                                  //   child:
                                                                  //       Padding(
                                                                  //     padding: const EdgeInsets
                                                                  //         .only(
                                                                  //         left:
                                                                  //             8.0),
                                                                  //     child:
                                                                  //         Row(
                                                                  //       mainAxisAlignment:
                                                                  //           MainAxisAlignment.center,
                                                                  //       children: [
                                                                  //         const Icon(
                                                                  //           Icons.people_alt_outlined,
                                                                  //           size:
                                                                  //               18,
                                                                  //           color:
                                                                  //               AppColors.white,
                                                                  //         ),
                                                                  //         Padding(
                                                                  //           padding:
                                                                  //               const EdgeInsets.only(left: 5.0),
                                                                  //           child:
                                                                  //               Text(
                                                                  //             textScaleFactor: 1.0,
                                                                  //             ekubs[index].equbers?.length.toString() ?? '0',
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
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          right:
                                                                              8.0),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          const Icon(
                                                                            Icons.loop_rounded,
                                                                            size:
                                                                                18,
                                                                            color:
                                                                                AppColors.white,
                                                                          ),
                                                                          Text(
                                                                            textScaleFactor:
                                                                                1.0,
                                                                            ekubs[index].numberOfEqubers.toString(),
                                                                            style:
                                                                                const TextStyle(
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
                                                                    child:
                                                                        Column(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Text(
                                                                          textScaleFactor:
                                                                              1.0,
                                                                          ekubs[index]
                                                                              .name,
                                                                          style:
                                                                              const TextStyle(
                                                                            fontFamily:
                                                                                'Poppins',
                                                                            fontSize:
                                                                                16,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            color:
                                                                                AppColors.white,
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              120.w,
                                                                          child:
                                                                              FittedBox(
                                                                            fit:
                                                                                BoxFit.scaleDown,
                                                                            child:
                                                                                Text(
                                                                              textScaleFactor: 1.0,
                                                                              numberFormat.format(ekubs[index].ekubAmount * ekubs[index].numberOfEqubers),
                                                                              style: TextStyle(
                                                                                fontFamily: 'Poppins',
                                                                                fontSize: 28.sp,
                                                                                fontWeight: FontWeight.w900,
                                                                                color: AppColors.white,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              20,
                                                                          child: ekubs[index].status == "completed"
                                                                              ? const SizedBox.shrink()
                                                                              : OutlinedButton(
                                                                                  style: OutlinedButton.styleFrom(backgroundColor: AppColors.white),
                                                                                  onPressed: () {
                                                                                    Navigator.push(
                                                                                      context,
                                                                                      MaterialPageRoute(
                                                                                        builder: (context) => EqubJoinDetail(
                                                                                          equb: EqubModel(isActive: false),
                                                                                          equbType: widget.type,
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  },
                                                                                  child: Text(
                                                                                    textScaleFactor: 1.0,
                                                                                    AppKeys.join.tr(context),
                                                                                    style: const TextStyle(color: AppColors.black),
                                                                                  ),
                                                                                ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  // Row(
                                                                  //   mainAxisAlignment:
                                                                  //       MainAxisAlignment
                                                                  //           .spaceBetween,
                                                                  //   children: [
                                                                  //     Padding(
                                                                  //       padding: const EdgeInsets
                                                                  //           .only(
                                                                  //           top:
                                                                  //               8.0,
                                                                  //           right:
                                                                  //               20),
                                                                  //       child: Image
                                                                  //           .asset(
                                                                  //         'assets/birr.png',
                                                                  //         height:
                                                                  //             92,
                                                                  //         width:
                                                                  //             92,
                                                                  //         fit: BoxFit
                                                                  //             .cover,
                                                                  //       ),
                                                                  //     ),
                                                                  //     Padding(
                                                                  //       padding: const EdgeInsets
                                                                  //           .only(
                                                                  //           top:
                                                                  //               5.0,
                                                                  //           left:
                                                                  //               78),
                                                                  //       child: Image
                                                                  //           .asset(
                                                                  //         'assets/birr2.png',
                                                                  //         height:
                                                                  //             92,
                                                                  //         width:
                                                                  //             92,
                                                                  //         fit: BoxFit
                                                                  //             .cover,
                                                                  //       ),
                                                                  //     ),
                                                                  //   ],
                                                                  // ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                const SizedBox(
                                  height: 30,
                                )
                              ],
                            ),
                ),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) async {
          switch (index) {
            case 0:
              final ekubCategorys = await loadEkubCategories();

              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const PaymentList()));
              break;
            case 1:
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()));
              break;
            case 2:
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TransactionHistory()));
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
          // Handle bottom navigation tab selection
        },
      ),
    );
  }
}
