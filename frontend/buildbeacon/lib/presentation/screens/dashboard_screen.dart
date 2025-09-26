import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buildbeacon/app/providers.dart';
import 'package:buildbeacon/data/models/build_models_simple.dart';
import 'package:buildbeacon/app/router.dart';
import 'package:buildbeacon/presentation/widgets/job_card.dart';
import 'package:buildbeacon/presentation/widgets/jobs_filter_bar.dart';
import 'package:buildbeacon/presentation/widgets/empty_state.dart';
import 'package:buildbeacon/presentation/widgets/error_card.dart';
import 'package:buildbeacon/theme.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Refresh when near the end to simulate pagination/loading more
      ref.refresh(jobsListProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobsListProvider);
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding =
        width > 1200 ? (width - 1040) / 2 : (width > 800 ? 32.0 : 16.0);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(context, horizontalPadding),
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 16),
              child: Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: const JobsFilterBar(),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding:
                EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 100),
            sliver: _buildJobsList(jobsState),
          ),
        ],
        key: UniqueKey(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goToNewBuild(),
        backgroundColor: LightModeColors.lightPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Build'),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, double horizontalPadding) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          return FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(left: horizontalPadding, bottom: 16),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BuildEngine',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: LightModeColors.lightOnSurface,
                      ),
                ),
                Text(
                  "Your Flutter  build factory",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: LightModeColors.lightNeutral600,
                      ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.goToSettings(),
          tooltip: 'Settings',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.refresh(jobsListProvider),
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.goToDashboard(),
          tooltip: 'Home',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildJobsList(AsyncValue<JobsListResponse> jobsState) {
    return jobsState.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ErrorCard(
            message: error.toString(),
            onRetry: () => ref.refresh(jobsListProvider),
          ),
        ),
      ),
      data: (response) {
        if (response.jobs.isEmpty) {
          return SliverFillRemaining(
            child: EmptyState(
              icon: Icons.work_outline,
              title: 'No builds yet',
              message: 'Create your first Flutter web build to get started.',
              actionText: 'New Build',
              onAction: () => context.goToNewBuild(),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final job = response.jobs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: JobCard(
                    job: job,
                    onTap: () => context.goToJobDetail(job.id),
                  ),
                );
              },
              childCount: response.jobs.length,
            ),
          ),
        );
      },
    );
  }
}
