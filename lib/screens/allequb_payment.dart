import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/provider/allequb_payment.dart';
import 'package:helloequb/screens/join_ekub_detail.dart';
import 'package:helloequb/screens/my_ekub_detail_screen.dart';
import 'package:helloequb/screens/payment_arrangement_screen.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import '../models/ekub_category_model.dart';
import '../utils/colors_constant.dart';
import '../utils/style_constants.dart';
import '../utils/getx_storage_custom.dart';
import '../utils/lang_constants.dart';
import 'transaction_history.dart';

class PaymentList extends StatefulWidget {
  final bool embedInShell;

  const PaymentList({super.key, this.embedInShell = false});

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshData();
    });
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
      backgroundColor: Colors.white,
      extendBody: !widget.embedInShell,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(AppKeys.payment.tr(context)),
      ),
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
                    style: AppTextStyles.bodyLarge.copyWith(
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
                        style: AppTextStyles.greyCaption,
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
                    color: const Color(0xFFF7F8FA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    elevation: 0,
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
                                  style: AppTextStyles.poppins60014.copyWith(
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
                                  style: AppTextStyles.badge.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Category left, type (daily/monthly) right
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoChip(
                                  Icons.label_outline,
                                  equb.equbCategory?.name ?? 'N/A',
                                ),
                              ),
                              Expanded(
                                child: _buildInfoChip(
                                  Icons.category_outlined,
                                  equb.equbType?.name ?? 'N/A',
                                  alignEnd: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Equb Amount
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppKeys.amount.tr(context),
                                      style: AppTextStyles.captionMuted,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      numberFormat.format(equb.equbAmount ?? 0),
                                      style: AppTextStyles.labelSmall.copyWith(
                                        fontWeight: FontWeight.w700,
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
                                      style: AppTextStyles.captionMuted,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      numberFormat.format(
                                        (equb.equbAmount ?? 0) *
                                            (int.tryParse(equb.numberOfEqubers
                                                    .toString()) ??
                                                0),
                                      ),
                                      style: AppTextStyles.labelSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Lottery Numbers — label left, chips right
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${AppKeys.lotteryNumbers.tr(context)}:',
                                style: AppTextStyles.captionMuted.copyWith(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: (equb.equbers != null &&
                                        equb.equbers!.isNotEmpty)
                                    ? Wrap(
                                        alignment: WrapAlignment.end,
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: equb.equbers!
                                            .map((e) => Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    border: Border.all(
                                                      color: AppColors.primary
                                                          .withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    e.lotteryNumber ?? "",
                                                    style: AppTextStyles
                                                        .labelSmall
                                                        .copyWith(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                      )
                                    : Text(
                                        AppKeys.noData.tr(context),
                                        textAlign: TextAlign.end,
                                        style:
                                            AppTextStyles.captionMuted.copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Go to Payment Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.payment,
                                  size: 18, color: Colors.white),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                              onPressed: () {
                                listItems.clear();
                                listItemss.clear();
                                for (int i = 0;
                                    i < (equb.equbers?.length ?? 0);
                                    i++) {
                                  listItemss.add(ListItems(
                                    title:
                                        equb.equbers?[i].lotteryNumber ?? '',
                                    subtitle: equb.equbAmount.toString(),
                                    userIds: equb.equbers?[i].id ?? '',
                                  ));
                                  listItems.add(ListItem(
                                    title:
                                        equb.equbers?[i].lotteryNumber ?? '',
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
                                style: AppTextStyles.button
                                    .copyWith(color: Colors.white),
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
      bottomNavigationBar: null,
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {bool alignEnd = false}) {
    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!alignEnd) ...[
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.captionMuted.copyWith(
              color: Colors.grey.shade800,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          ),
        ),
        if (alignEnd) ...[
          const SizedBox(width: 4),
          Icon(icon, size: 14, color: AppColors.primary),
        ],
      ],
    );
  }
}
