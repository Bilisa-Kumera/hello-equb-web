import 'package:dio/dio.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/models/equb_history_model.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/secure_storage.dart';
import 'package:helloequb/utils/style_constants.dart';

enum _HistoryFilter { all, active, completed }

class EqubHistoryScreen extends StatefulWidget {
  const EqubHistoryScreen({super.key});

  @override
  State<EqubHistoryScreen> createState() => _EqubHistoryScreenState();
}

class _EqubHistoryScreenState extends State<EqubHistoryScreen> {
  final Dio _dio = Dio();
  final ScrollController _scrollController = ScrollController();

  final List<EqubHistoryEqub> _equbs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  int _page = 1;
  final int _limit = 11;
  int _total = 0;
  bool _hasMore = true;

  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    _fetch(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    final pos = _scrollController.position;
    if (!pos.hasPixels) return;
    if (pos.pixels >= pos.maxScrollExtent - 320) {
      _fetchMore();
    }
  }

  Future<void> _fetch({required bool reset}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 1;
        _total = 0;
        _hasMore = true;
        _equbs.clear();
      });
    } else {
      setState(() {
        _isLoadingMore = true;
        _error = null;
      });
    }

    try {
      final userId = await SecureStorageHelper.getUserId() ?? '';
      final token = await SecureStorageHelper.getAccessToken() ?? '';

      if (userId.isEmpty) {
        throw Exception('Missing userId');
      }

      final url = '$getEqubHistoryUrl?user=$userId&_page=$_page&_limit=$_limit';
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final parsed = EqubHistoryResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );

      final newEqubs = parsed.data.equbs;
      final meta = parsed.data.meta;
      final total = meta?.total ?? (reset ? newEqubs.length : _total);

      setState(() {
        _equbs.addAll(newEqubs);
        _total = total;
        _hasMore = _equbs.length < _total;
        _isLoading = false;
        _isLoadingMore = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _fetchMore() async {
    if (!_hasMore) return;
    _page += 1;
    await _fetch(reset: false);
  }

  Future<void> _onRefresh() async {
    await _fetch(reset: true);
  }

  List<EqubHistoryEqub> get _filteredEqubs {
    if (_filter == _HistoryFilter.all) return _equbs;
    if (_filter == _HistoryFilter.active) {
      // Active = registering or started (in-progress equbs).
      return _equbs.where((e) {
        final s = e.status.toLowerCase();
        return s == 'registering' || s == 'started';
      }).toList();
    }
    return _equbs.where((e) => e.status.toLowerCase() == 'completed').toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredEqubs;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppKeys.equbHistory.tr(context),
          style: AppTextStyles.poppins60014,
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: _FilterBar(
                  filter: _filter,
                  total: _equbs.length,
                  onChange: (f) => setState(() => _filter = f),
                ),
              ),
            ),
            if (_isLoading) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            ] else if (_error != null) ...[
              SliverToBoxAdapter(
                child: _ErrorState(
                  message: _error!,
                  onRetry: () => _fetch(reset: true),
                ),
              ),
            ] else if (list.isEmpty) ...[
              SliverToBoxAdapter(
                child: _EmptyState(
                  title: AppKeys.noData.tr(context),
                  subtitle: AppKeys.retry.tr(context),
                  onRetry: () => _fetch(reset: true),
                ),
              ),
            ] else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final equb = list[index];
                    return _EqubHistoryCard(
                      equb: equb,
                      onTap: () => _showDetails(equb),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: _isLoadingMore
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : (!_hasMore && _equbs.isNotEmpty)
                            ? Text(
                                '${_equbs.length} / $_total',
                                style: AppTextStyles.poppins60014
                                    .copyWith(color: Colors.grey.shade600),
                              )
                            : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetails(EqubHistoryEqub equb) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _EqubHistoryDetailsSheet(equb: equb),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _HistoryFilter filter;
  final int total;
  final ValueChanged<_HistoryFilter> onChange;

  const _FilterBar({
    required this.filter,
    required this.total,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, _HistoryFilter value) {
      final selected = filter == value;
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChange(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.12)
                : const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade200,
            ),
          ),
          child: Text(
            label,
            style: selected
                ? AppTextStyles.labelSmall.copyWith(color: AppColors.primary)
                : AppTextStyles.captionMuted.copyWith(color: Colors.grey.shade700),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('All ($total)', _HistoryFilter.all),
        const SizedBox(width: 10),
        chip('Active', _HistoryFilter.active),
        const SizedBox(width: 10),
        chip('Completed', _HistoryFilter.completed),
      ],
    );
  }
}

class _EqubHistoryCard extends StatelessWidget {
  final EqubHistoryEqub equb;
  final VoidCallback onTap;

  const _EqubHistoryCard({
    required this.equb,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = equb.status.isNotEmpty ? equb.status : equb.state;
    final statusLower = status.toLowerCase();
    final chipColor = statusLower == 'completed'
        ? Colors.blueGrey
        : (statusLower == 'started' || statusLower == 'registering'
            ? AppColors.primary
            : Colors.orange);

    final approvedCount = equb.payments.where((p) => p.approved).length;
    final totalPaidAmount = approvedCount * equb.equbAmount;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.primary.withOpacity(0.10),
                  ),
                  child: const Icon(
                    Icons.groups_2_outlined,
                    size: 20,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equb.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.poppins60014,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        equb.description.isNotEmpty
                            ? equb.description
                            : 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionMuted.copyWith(
                          color: Colors.grey.shade600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: chipColor.withOpacity(0.25)),
                  ),
                  child: Text(
                    status.isEmpty ? 'Unknown' : status,
                    style: AppTextStyles.captionMuted.copyWith(color: chipColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniStat(
                  icon: Icons.people_outline,
                  label: '${equb.numberOfEqubers} members',
                ),
                _MiniStat(
                  icon: Icons.payments_outlined,
                  label: '${numberFormat.format(equb.equbAmount)} ETB',
                ),
                _MiniStat(
                  icon: Icons.receipt_long_outlined,
                  label: '${equb.payments.length} payments',
                ),
                _MiniStat(
                  icon: Icons.verified_outlined,
                  label: '$approvedCount approved',
                ),
                _MiniStat(
                  icon: Icons.account_balance_wallet_outlined,
                  label:
                      '${AppKeys.totalPaid.tr(context)}: ${numberFormat.format(totalPaidAmount)} ETB',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EqubHistoryDetailsSheet extends StatelessWidget {
  final EqubHistoryEqub equb;
  const _EqubHistoryDetailsSheet({required this.equb});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, yyyy');

    String fmtDate(DateTime? dt) => dt == null ? '-' : df.format(dt.toLocal());

    final status = equb.status.isNotEmpty ? equb.status : equb.state;
    final statusLower = status.toLowerCase();
    final chipColor = statusLower == 'completed'
        ? Colors.blueGrey
        : (statusLower == 'started' || statusLower == 'registering'
            ? AppColors.primary
            : Colors.orange);
    final approvedCount = equb.payments.where((p) => p.approved).length;
    final totalPaidAmount = approvedCount * equb.equbAmount;
    final lastPayment = equb.payments.isEmpty
        ? null
        : (equb.payments.toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(1970))
              .compareTo(a.createdAt ?? DateTime(1970))))
            .first;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.primary.withOpacity(0.10),
                  ),
                  child: const Icon(
                    Icons.groups_2_outlined,
                    size: 21,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equb.name,
                        style: AppTextStyles.poppins60014,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        equb.description.isNotEmpty
                            ? equb.description
                            : 'No description',
                        style: AppTextStyles.captionMuted.copyWith(
                          color: Colors.grey.shade600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: chipColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: chipColor.withOpacity(0.25)),
                  ),
                  child: Text(
                    status.isEmpty ? 'Unknown' : status,
                    style: AppTextStyles.captionMuted.copyWith(color: chipColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _summaryTile(
                    Icons.payments_outlined,
                    AppKeys.equbAmount.tr(context),
                    '${numberFormat.format(equb.equbAmount)} ETB',
                  ),
                  _summaryTile(
                    Icons.verified_outlined,
                    'Approved',
                    approvedCount.toString(),
                  ),
                  _summaryTile(
                    Icons.account_balance_wallet_outlined,
                    AppKeys.totalPaid.tr(context),
                    '${numberFormat.format(totalPaidAmount)} ETB',
                  ),
                  _summaryTile(
                    Icons.people_outline,
                    'Members',
                    equb.numberOfEqubers.toString(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _infoCard([
              _InfoRow('Type', equb.equbType?.name ?? '-'),
              _InfoRow('Category', equb.equbCategory?.name ?? '-'),
              _InfoRow('Branch', equb.branch?.name ?? '-'),
              _InfoRow('Service charge', '${equb.serviceCharge}%'),
            ]),
            const SizedBox(height: 12),
            _infoCard([
              _InfoRow('Start date', fmtDate(equb.startDate)),
              _InfoRow('Next round date', fmtDate(equb.nextRoundDate)),
              _InfoRow(
                'Next round time',
                equb.nextRoundTime.isEmpty ? '-' : equb.nextRoundTime,
              ),
              _InfoRow(
                'Next lottery type',
                equb.nextRoundLotteryType.isEmpty
                    ? '-'
                    : equb.nextRoundLotteryType,
              ),
            ]),
            const SizedBox(height: 12),
            _infoCard([
              _InfoRow('Previous round', equb.previousRound.toString()),
              _InfoRow('Current round', equb.currentRound.toString()),
              _InfoRow('Next round', equb.nextRound.toString()),
              _InfoRow(
                'Has last round winner',
                equb.hasLastRoundWinner ? 'Yes' : 'No',
              ),
            ]),
            const SizedBox(height: 14),
            Text(
              'Payments',
              style: AppTextStyles.poppins60014,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _pill('${equb.payments.length} total'),
                const SizedBox(width: 10),
                _pill('$approvedCount approved'),
              ],
            ),
            const SizedBox(height: 10),
            if (lastPayment != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last payment',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${lastPayment.type} - ${numberFormat.format(lastPayment.amount)} ETB',
                      style: AppTextStyles.poppins60014,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lastPayment.paymentMethod} - round ${lastPayment.round} - ${lastPayment.approved ? 'approved' : 'pending'}',
                      style: AppTextStyles.captionMuted.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                'No payments found for this equb.',
                style: AppTextStyles.poppins60014.copyWith(color: Colors.grey.shade700),
              ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              k,
              style: AppTextStyles.poppins70014.copyWith(color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: AppTextStyles.poppins40014.copyWith(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(IconData icon, String label, String value) {
    return Container(
      width: 142,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.captionMuted.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _infoCard(List<_InfoRow> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: rows.map((row) => _kv(row.label, row.value)).toList(),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withOpacity(0.20)),
      ),
      child: Text(
        text,
        style: AppTextStyles.poppins40014.copyWith(color: Colors.black87),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRetry;
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.10),
            ),
            child: const Icon(Icons.history, size: 34, color: Colors.black87),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTextStyles.poppins60014.copyWith(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: Text(
              AppKeys.retry.tr(context),
              style: AppTextStyles.poppins40014.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.08),
            ),
            child: const Icon(Icons.error_outline,
                size: 34, color: Colors.redAccent),
          ),
          const SizedBox(height: 14),
          Text(
            'Failed to load',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.poppins60014.copyWith(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: Text(
              AppKeys.retry.tr(context),
              style: AppTextStyles.poppins40014.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
