import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drivesense/ui/core/widgets/app_bottom_navbar.dart';
import 'package:drivesense/ui/core/widgets/app_header_bar.dart';
import 'package:drivesense/ui/driving_history_analysis/view_model/analysis_view_model.dart';
import 'package:drivesense/ui/driving_history_analysis/analysis/driving_analysis_view.dart';
import 'package:drivesense/domain/models/driving_history/driving_history.dart';
import 'package:drivesense/domain/models/accident/accident.dart';
import 'package:drivesense/domain/models/risky_behaviour/risky_behaviour.dart';
import 'package:drivesense/ui/core/themes/colors.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class DrivingHistoryView extends StatefulWidget {
  const DrivingHistoryView({super.key});

  @override
  State<DrivingHistoryView> createState() => _DrivingHistoryViewState();
}

class _DrivingHistoryViewState extends State<DrivingHistoryView> {
  @override
  void initState() {
    super.initState();
    // Load data when view is initialized
    Future.microtask(
      () =>
          Provider.of<AnalysisViewModel>(
            context,
            listen: false,
          ).loadDrivingHistory(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AnalysisViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppHeaderBar(
            title: 'Driving History',
            leading: const Icon(Icons.arrow_back),
            onLeadingPressed: () => context.go('/'),
          ),
          body:
              viewModel.isLoading
                  ? _buildLoadingView()
                  : viewModel.errorMessage != null
                  ? _buildErrorView(viewModel.errorMessage!)
                  : _buildContentView(context, viewModel),
          bottomNavigationBar: const AppBottomNavBar(
            currentRoute: '/driving_history',
          ),
        );
      },
    );
  }

  Widget _buildLoadingView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDarkMode ? AppColors.blue : AppColors.darkBlue,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading your driving history...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String errorMessage) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: AppColors.red.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Provider.of<AnalysisViewModel>(
                  context,
                  listen: false,
                ).loadDrivingHistory();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDarkMode ? AppColors.blue : AppColors.darkBlue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Retry',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentView(BuildContext context, AnalysisViewModel viewModel) {
    return Column(
      children: [
        _buildMonthSelector(viewModel),
        _buildStatsSummary(viewModel),
        _buildDrivingTipsCard(), // Add this line
        Expanded(
          child:
              viewModel.drivingHistory.isEmpty
                  ? _buildEmptyState()
                  : _buildDrivingHistoryList(viewModel),
        ),
      ],
    );
  }

  Widget _buildMonthSelector(AnalysisViewModel viewModel) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? AppColors.blackTransparent.withValues(alpha: 0.2)
                : AppColors.lightGrey,
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: AppColors.blackTransparent.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => viewModel.previousMonth(),
            color: isDarkMode ? AppColors.blue : AppColors.darkBlue,
          ),
          Text(
            DateFormat('MMMM yyyy').format(viewModel.selectedMonth),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? AppColors.white : AppColors.darkBlue,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => viewModel.nextMonth(),
            color: isDarkMode ? AppColors.blue : AppColors.darkBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(AnalysisViewModel viewModel) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDarkMode
                ? AppColors.darkBlue.withValues(alpha: 0.8)
                : AppColors.darkBlue,
            isDarkMode ? AppColors.blue.withValues(alpha: 0.9) : AppColors.blue,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                viewModel.totalDrivingSessions.toString(),
                'Drives',
                Icons.drive_eta,
              ),
              _buildStatItem(
                '${viewModel.totalDrivingMinutes} min',
                'Duration',
                Icons.timer,
              ),
              _buildStatItem(
                viewModel.totalRiskyBehaviors.toString(),
                'Alerts',
                Icons.warning_amber,
                isAlert: viewModel.totalRiskyBehaviors > 0,
              ),
              _buildStatItem(
                viewModel.totalAccidents.toString(),
                'Accidents',
                Icons.car_crash,
                isAlert: viewModel.totalAccidents > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon, {
    bool isAlert = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isAlert
                    ? AppColors.red.withValues(alpha: 0.2)
                    : AppColors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 80,
              color:
                  isDarkMode
                      ? AppColors.greyBlue
                      : AppColors.darkBlue.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No driving records',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No driving activity recorded for this month.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrivingHistoryList(AnalysisViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.drivingHistory.length,
      itemBuilder: (context, index) {
        final history = viewModel.drivingHistory[index];
        return _buildDrivingHistoryCard(context, history, viewModel);
      },
    );
  }

  Widget _buildDrivingHistoryCard(
    BuildContext context,
    DrivingHistory history,
    AnalysisViewModel viewModel,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasRiskyBehavior = history.riskyBehaviour.isNotEmpty;
    final hasAccidents = history.accident.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? AppColors.blackTransparent.withValues(alpha: 0.3)
                : AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: AppColors.blackTransparent.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor:
                isDarkMode
                    ? AppColors.greyBlue.withValues(alpha: 0.2)
                    : AppColors.lightGrey,
            expansionTileTheme: ExpansionTileThemeData(
              backgroundColor:
                  isDarkMode
                      ? AppColors.blackTransparent.withValues(alpha: 0.2)
                      : AppColors.white,
            ),
          ),
          child: ExpansionTile(
            childrenPadding: const EdgeInsets.all(16),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? AppColors.blue.withValues(alpha: 0.15)
                            : AppColors.darkBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.drive_eta,
                    color: isDarkMode ? AppColors.blue : AppColors.darkBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewModel.formatDate(history.startTime),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? AppColors.white : AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${viewModel.formatTime(history.startTime)} - ${viewModel.formatTime(history.endTime)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      viewModel.getFormattedDuration(history),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hasRiskyBehavior || hasAccidents)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasRiskyBehavior)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${history.riskyBehaviour.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (hasAccidents)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${history.accident.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors:
                        isDarkMode
                            ? [
                              AppColors.blue.withValues(alpha: 0.8),
                              AppColors.darkBlue.withValues(alpha: 0.9),
                            ]
                            : [
                              AppColors.darkBlue,
                              AppColors.darkBlue.withValues(alpha: 0.8),
                            ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isDarkMode
                              ? AppColors.blue.withValues(alpha: 0.3)
                              : AppColors.darkBlue.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => DrivingAnalysisView(
                                drivingHistoryId: history.drivingHistoryId!,
                              ),
                        ),
                      );
                    },
                    splashColor: Colors.white.withValues(alpha: 0.1),
                    highlightColor: Colors.white.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Hero(
                                tag:
                                    'analysis_icon_${history.drivingHistoryId}',
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.analytics_outlined,
                                    color: AppColors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'View Detailed Analysis',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: AppColors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (hasRiskyBehavior) ...[
                Text(
                  'Risk Alerts',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildRiskyBehaviorList(history.riskyBehaviour),
              ],
              if (hasAccidents) ...[
                const SizedBox(height: 16),
                Text(
                  'Accidents',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildAccidentList(history.accident),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskyBehaviorList(List<RiskyBehaviour> behaviors) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? AppColors.blackTransparent.withValues(alpha: 0.1)
                : AppColors.lightGrey.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(top: 4),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: behaviors.length,
        separatorBuilder:
            (context, index) => Divider(
              height: 1,
              color:
                  isDarkMode
                      ? AppColors.greyBlue.withValues(alpha: 0.1)
                      : AppColors.whiteGrey,
            ),
        itemBuilder: (context, index) {
          final behavior = behaviors[index];
          return ListTile(
            leading: _getRiskyBehaviorIcon(behavior.behaviourType),
            title: Text(
              behavior.behaviourType,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              DateFormat('h:mm a').format(behavior.detectedTime),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccidentList(List<Accident> accidents) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? AppColors.red.withValues(alpha: 0.1)
                : AppColors.redWhite,
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(top: 4),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: accidents.length,
        separatorBuilder:
            (context, index) => Divider(
              height: 1,
              color:
                  isDarkMode
                      ? AppColors.greyBlue.withValues(alpha: 0.1)
                      : AppColors.whiteGrey,
            ),
        itemBuilder: (context, index) {
          final accident = accidents[index];
          return ListTile(
            leading: const Icon(Icons.car_crash, color: AppColors.red),
            title: Text(
              'Accident (${accident.location})',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('h:mm a').format(accident.detectedTime),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Emergency Contact: ${accident.contactNum}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
          );
        },
      ),
    );
  }

  Widget _getRiskyBehaviorIcon(String behaviourType) {
    IconData iconData;
    Color iconColor;

    switch (behaviourType.toLowerCase()) {
      case 'drowsiness':
        iconData = Icons.bedtime_outlined;
        iconColor = AppColors.lightPurple;
        break;
      case 'distraction':
        iconData = Icons.phone_android;
        iconColor = AppColors.blue;
        break;
      case 'intoxication':
        iconData = Icons.local_bar;
        iconColor = AppColors.red;
        break;
      case 'phone usage':
        iconData = Icons.smartphone;
        iconColor = AppColors.blue;
        break;
      case 'distress':
        iconData = Icons.sentiment_very_dissatisfied;
        iconColor = AppColors.red;
        break;
      default:
        iconData = Icons.warning_amber;
        iconColor =
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.blue
                : AppColors.darkBlue;
    }

    return Icon(iconData, color: iconColor);
  }

  Widget _buildDrivingTipsCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Map<String, dynamic>>(
      future:
          Provider.of<AnalysisViewModel>(
            context,
            listen: false,
          ).getDrivingTips(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            height: 100,
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? AppColors.blackTransparent.withValues(alpha: 0.3)
                      : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                if (!isDarkMode)
                  BoxShadow(
                    color: AppColors.blackTransparent.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: isDarkMode ? AppColors.blue : AppColors.darkBlue,
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final drivingTips = data['drivingTips'] as String;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDarkMode
                      ? [
                        AppColors.darkGrey.withValues(alpha: 0.9),
                        Colors.black.withValues(alpha: 0.7),
                      ]
                      : [AppColors.lightGrey.withValues(alpha: 0.5), Colors.white],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.blackTransparent.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color:
                  isDarkMode
                      ? AppColors.greyBlue.withValues(alpha: 0.3)
                      : AppColors.greyBlue.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // Background decoration
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 120,
                    color:
                        isDarkMode
                            ? AppColors.greyBlue.withValues(alpha: 0.05)
                            : AppColors.greyBlue.withValues(alpha: 0.1),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? AppColors.blue.withValues(alpha: 0.2)
                                      : AppColors.blue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.tips_and_updates,
                              color:
                                  isDarkMode
                                      ? AppColors.blue
                                      : AppColors.darkBlue,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Driving Insights',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  isDarkMode
                                      ? AppColors.white
                                      : AppColors.darkBlue,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? AppColors.grey.withValues(alpha: 0.2)
                                      : AppColors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 12,
                                  color:
                                      isDarkMode
                                          ? AppColors.blue
                                          : AppColors.darkBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'AI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isDarkMode
                                            ? AppColors.greyBlue
                                            : AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          drivingTips,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                isDarkMode
                                    ? AppColors.white.withValues(alpha: 0.9)
                                    : AppColors.darkGrey,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
