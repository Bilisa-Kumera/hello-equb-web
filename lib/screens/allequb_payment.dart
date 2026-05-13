import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/provider/allequb_payment.dart';
import 'package:ekubee/screens/join_ekub_detail.dart';
import 'package:ekubee/screens/my_ekub_detail_screen.dart';
import 'package:ekubee/screens/payment_arrangement_screen.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import '../models/ekub_category_model.dart';
import '../utils/colors_constant.dart';
import '../utils/custom_bottom_nav.dart';
import '../utils/getx_storage_custom.dart';
import '../utils/lang_constants.dart';
import 'home_screen.dart';
import 'my_other_ekubs.dart';
import 'profile_screen.dart';
import 'transaction_history.dart';

class PaymentList extends StatefulWidget {
  const PaymentList({super.key});

  @override
  State<PaymentList> createState() => _PaymentListState();
}

class _PaymentListState extends State<PaymentList> {
  final ScrollController _scrollController = ScrollController();
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data every time the page is visited
    _refreshData();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200) {
        final provider = Provider.of<EqubPaymentProvider>(context, listen: false);
        if (!provider.isLoading) {
          provider.loadMore();
        }
      }
    });
  }

  Future<void> _refreshData() async {
    final provider = Provider.of<EqubPaymentProvider>(context, listen: false);
    
    // Only show loading indicator on initial load, not during refresh
    if (_isInitializing) {
      setState(() {});
    }
    
    await provider.refreshEqubs();
    
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<ListItems> listItemss = [];
  List<ListItem> listItems = [];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppKeys.payment.tr(context))),
      body: Consumer<EqubPaymentProvider>(
        builder: (context, provider, child) {
          // Show loading only on initial load when data is empty
          if (_isInitializing && provider.equbs.isEmpty) {
            return Center(
              child: LoadingAnimationWidget.threeRotatingDots(
                color: AppColors.vibrantGreen,
                size: 30,
              ),
            );
          }

          // Show empty state if no data and not loading
          if (provider.equbs.isEmpty && !provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.primary,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.lastError == null
                        ? AppKeys.noEkubs.tr(context)
                        : AppKeys.errorTryAgain.tr(context),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                  if (provider.lastError != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        provider.lastError!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(AppKeys.retry.tr(context)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: _refreshData,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            displacement: 40,
            color: AppColors.primary,
            backgroundColor: Colors.white,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.equbs.length + (provider.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at bottom during pagination
                if (index == provider.equbs.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }

                final equb = provider.equbs[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    shadowColor: Colors.grey.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Equb Name
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  equb.name ?? "No Name",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "${AppKeys.round.tr(context)}: ${equb.currentRound}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Equb Type and Category
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildInfoChip(
                                  Icons.category_outlined,
                                  equb.equbType?.name ?? 'N/A',
                                ),
                              ),
                              Expanded(
                                child: _buildInfoChip(
                                  Icons.label_outline,
                                  equb.equbCategory?.name ?? 'N/A',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Equb Amount
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppKeys.amount.tr(context),
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      numberFormat.format(equb.equbAmount ?? 0),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppKeys.totalAmount.tr(context),
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      numberFormat.format(
                                        (equb.equbAmount ?? 0) * 
                                        (int.tryParse(equb.numberOfEqubers.toString()) ?? 0)
                                      ),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.vibrantGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Lottery Numbers
                          if (equb.equbers != null && equb.equbers!.isNotEmpty) ...[
                            Text(
                              'Your Lottery Numbers:',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: equb.equbers!
                                  .map((e) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppColors.primary.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          e.lotteryNumber ?? "",
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ] else
                            Text(
                              "No Lottery Numbers",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Go to Payment Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.payment, size: 20),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                elevation: 2,
                              ),
                              onPressed: () {
                                listItems.clear();
                                listItemss.clear();
                                for (int i = 0; i < (equb.equbers?.length ?? 0); i++) {
                                  listItemss.add(ListItems(
                                    title: equb.equbers?[i].lotteryNumber ?? '',
                                    subtitle: equb.equbAmount.toString(),
                                    userIds: equb.equbers?[i].id ?? '',
                                  ));
                                  listItems.add(ListItem(
                                    title: equb.equbers?[i].lotteryNumber ?? '',
                                    subtitle: equb.equbAmount.toString(),
                                  ));
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentArragement(
                                      selectedJoinOption: listItems,
                                      selectedJoinOptions: listItemss,
                                      ekubAmount: equb.equbAmount.toString(),
                                      ekubId: equb.id,
                                      ekubName: equb.name,
                                      ekubRound: equb.currentRound.toString(),
                                      round: equb.currentRound.toString(),
                                      expectedAmount: double.parse(
                                              equb.equbAmount.toString()) *
                                          double.parse(
                                              equb.numberOfEqubers.toString()),
                                      type: 'payment',
                                    ),
                                  ),
                                );
                              },
                              label: Text(
                                AppKeys.makePayment.tr(context),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 2,
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
