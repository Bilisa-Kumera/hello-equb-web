import 'package:flutter/material.dart';
import '../../models/financeandothermodel.dart';
import 'package:helloequb/provider/equb_provider.dart';
import 'package:provider/provider.dart';
import '../equb_detail_card.dart';
import '../join_ekub_detail.dart';
import '../../utils/colors_constant.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../utils/lang_constants.dart';
import '../../utils/app_localizations.dart';

class EqubListByCategory extends StatefulWidget {
  final EqubCategory category;
  final String equbTypeId;
  final String type;

  const EqubListByCategory({
    super.key,
    required this.category,
    required this.equbTypeId,
    required this.type,
  });

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
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
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
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final showBottomItem = provider.isLoadingMore || provider.hasMore;

        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: provider.equbs.length + (showBottomItem ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            if (index >= provider.equbs.length) {
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
            final equb = provider.equbs[index];
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
                equb: equb,
                equbType: equb.equbType?.entries.first.value ?? '',
                type: equb.equbType?['name'],
              ),
            );
          },
        );
      },
    );
  }
}
