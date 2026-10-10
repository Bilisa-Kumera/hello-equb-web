import 'package:flutter/material.dart';
import '../../models/financeandothermodel.dart';
import 'package:helloequb/provider/equb_provider.dart';
import 'package:provider/provider.dart';
import '../equb_detail_card.dart';
import '../../utils/colors_constant.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../utils/lang_constants.dart';
import '../../utils/app_localizations.dart';
import 'package:helloequb/utils/style_constants.dart';

class EqubListByCategory extends StatefulWidget {
  final EqubCategory category;
  final String equbTypeId;
  final String type;
  final int tabIndex;

  const EqubListByCategory({
    super.key,
    required this.category,
    required this.equbTypeId,
    required this.type,
    this.tabIndex = 0,
  });

  @override
  State<EqubListByCategory> createState() => _EqubListByCategoryState();
}

class _EqubListByCategoryState extends State<EqubListByCategory> {
  final ScrollController _scrollController = ScrollController();
  TabController? _tabController;
  bool _listeningToTab = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.maybeOf(context);
    if (controller == null || _listeningToTab) return;
    _listeningToTab = true;
    _tabController = controller;
    _tabController!.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isSelectedTab()) _fetchForThisTab();
    });
  }

  bool _isSelectedTab() {
    final controller = _tabController;
    if (controller == null) return widget.tabIndex == 0;
    return !controller.indexIsChanging && controller.index == widget.tabIndex;
  }

  void _onTabChanged() {
    if (!mounted || !_isSelectedTab()) return;
    _fetchForThisTab();
  }

  void _fetchForThisTab() {
    final provider = context.read<EqubProvider>();
    final categoryId = widget.category.id ?? '';
    if (provider.matchesFilter(
          equbTypeId: widget.equbTypeId,
          equbCategoryId: categoryId,
        ) &&
        (provider.isLoading || provider.equbs.isNotEmpty)) {
      return;
    }
    provider.fetchEqubs(
      equbCategoryId: categoryId,
      equbTypeId: widget.equbTypeId,
    );
  }

  void _onScroll() {
    final provider = context.read<EqubProvider>();
    if (!provider.matchesFilter(
      equbTypeId: widget.equbTypeId,
      equbCategoryId: widget.category.id ?? '',
    )) {
      return;
    }
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
    _tabController?.removeListener(_onTabChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EqubProvider>(
      builder: (context, provider, _) {
        final matches = provider.matchesFilter(
          equbTypeId: widget.equbTypeId,
          equbCategoryId: widget.category.id ?? '',
        );

        if (!matches || provider.isLoading) {
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
                    style: AppTextStyles.poppins40014.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _fetchForThisTab,
                    child: Text(AppKeys.retry.tr(context)),
                  ),
                ],
              ),
            ),
          );
        }

        final sortedEqubs = provider.activeSortedEqubs;

        if (sortedEqubs.isEmpty) {
          return Center(
            child: Text(
              AppKeys.noEkubs.tr(context),
              style: AppTextStyles.poppins40016.copyWith(color: Colors.grey),
            ),
          );
        }

        final showBottomItem = provider.isLoadingMore || provider.hasMore;

        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: sortedEqubs.length + (showBottomItem ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 14),
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
            return EqubDetailCard(
              key: ValueKey(equb.id),
              equb: equb,
              equbType: equb.equbType?.entries.first.value ?? '',
              type: equb.equbType?['name'],
            );
          },
        );
      },
    );
  }
}
