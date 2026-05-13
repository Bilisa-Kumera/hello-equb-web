import 'package:dio/dio.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/models/equb_history_model.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/colors_constant.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/secure_storage.dart';

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
      return _equbs.where((e) {
        final s = e.status.toLowerCase();
        final st = e.state.toLowerCase();
        // Backend sometimes returns `state: active` even for completed equbs,
        // so we treat "active" as "not completed" by status.
        if (s.isNotEmpty) return s != 'completed';
        return st == 'active';
      }).toList();
    }
    return _equbs.where((e) => e.status.toLowerCase() == 'completed').toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredEqubs;

    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.grey50,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  AppKeys.equbHistory.tr(context),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.18),
                        Colors.white,
                      ],
                    ),
                  ),
                ),
              ),
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
                    child: Center(child: CircularProgressIndicator()),
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
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ],
          ),
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
        borderRadius: BorderRadius.circular(30),
        onTap: () => onChange(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade200,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.black87,
            ),
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
        : (statusLower == 'active' ? AppColors.primary : Colors.orange);

    final approvedCount = equb.payments.where((p) => p.approved).length;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.18),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.groups_2_outlined,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          equb.description.isNotEmpty
                              ? equb.description
                              : 'No description',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: chipColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: chipColor.withOpacity(0.25)),
                    ),
                    child: Text(
                      status.isEmpty ? 'Unknown' : status,
                      style: TextStyle(
                        color: chipColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
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
                ],
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              fontSize: 12.5,
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

    final approvedCount = equb.payments.where((p) => p.approved).length;
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
            Text(
              equb.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              equb.description.isNotEmpty ? equb.description : 'No description',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            _kv('Status', equb.status.isNotEmpty ? equb.status : '-'),
            _kv('State', equb.state.isNotEmpty ? equb.state : '-'),
            _kv('Type', equb.equbType?.name ?? '-'),
            _kv('Category', equb.equbCategory?.name ?? '-'),
            _kv('Branch', equb.branch?.name ?? '-'),
            const SizedBox(height: 12),
            _kv('Equb amount', '${numberFormat.format(equb.equbAmount)} ETB'),
            _kv('Members', equb.numberOfEqubers.toString()),
            _kv('Service charge', '${equb.serviceCharge}%'),
            const SizedBox(height: 12),
            _kv('Start date', fmtDate(equb.startDate)),
            _kv('Next round date', fmtDate(equb.nextRoundDate)),
            _kv('Next round time', equb.nextRoundTime.isEmpty ? '-' : equb.nextRoundTime),
            _kv('Next lottery type', equb.nextRoundLotteryType.isEmpty ? '-' : equb.nextRoundLotteryType),
            const SizedBox(height: 12),
            _kv('Rounds', 'prev ${equb.previousRound} | current ${equb.currentRound} | next ${equb.nextRound}'),
            _kv('Has last round winner', equb.hasLastRoundWinner ? 'Yes' : 'No'),
            const SizedBox(height: 14),
            const Text(
              'Payments',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last payment',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${lastPayment.type} • ${numberFormat.format(lastPayment.amount)} ETB',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lastPayment.paymentMethod} • round ${lastPayment.round} • ${lastPayment.approved ? 'approved' : 'pending'}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                'No payments found for this equb.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
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
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }
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
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
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
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
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
          const Text(
            'Failed to load',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
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
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
