import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drivesense/ui/core/widgets/app_bottom_navbar.dart';
import 'package:drivesense/ui/driving_history_analysis/view_model/analysis_view_model.dart';
import 'package:drivesense/ui/driving_history_analysis/analysis/driving_analysis_view.dart';
import 'package:drivesense/domain/models/driving_history/driving_history.dart';
import 'package:drivesense/domain/models/accident/accident.dart';
import 'package:drivesense/domain/models/risky_behaviour/risky_behaviour.dart';
import 'package:intl/intl.dart';

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
    return Consumer<AnalysisViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Driving History',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body:
              viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
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

  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            style: const TextStyle(fontSize: 16),
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
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView(BuildContext context, AnalysisViewModel viewModel) {
    return Column(
      children: [
        _buildMonthSelector(viewModel),
        _buildStatsSummary(viewModel),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF5F5F5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => viewModel.previousMonth(),
          ),
          Text(
            DateFormat('MMMM yyyy').format(viewModel.selectedMonth),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => viewModel.nextMonth(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(AnalysisViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            context,
            viewModel.totalDrivingSessions.toString(),
            'Drives',
            Icons.drive_eta,
          ),
          _buildStatCard(
            context,
            '${viewModel.totalDrivingMinutes} min',
            'Duration',
            Icons.timer,
          ),
          _buildStatCard(
            context,
            viewModel.totalRiskyBehaviors.toString(),
            'Alerts',
            Icons.warning_amber,
          ),
          _buildStatCard(
            context,
            viewModel.totalAccidents.toString(),
            'Accidents',
            Icons.car_crash,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.time_to_leave_outlined,
            size: 72,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No driving activity recorded\nfor this month',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
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
    final hasRiskyBehavior = history.riskyBehaviour.isNotEmpty;
    final hasAccidents = history.accident.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => DrivingAnalysisView(
                    drivingHistoryId: history.drivingHistoryId,
                  ),
            ),
          );
        },
        child: ExpansionTile(
          childrenPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.drive_eta, color: Color(0xFF1A237E)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewModel.formatDate(history.startTime),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${viewModel.formatTime(history.startTime)} - ${viewModel.formatTime(history.endTime)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    viewModel.getFormattedDuration(history),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (hasRiskyBehavior || hasAccidents)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasRiskyBehavior)
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${history.riskyBehaviour.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (hasAccidents)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${history.accident.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
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
            const Divider(),
            if (hasRiskyBehavior) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Risk Alerts',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              _buildRiskyBehaviorList(history.riskyBehaviour),
            ],
            if (hasAccidents) ...[
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Accidents',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              _buildAccidentList(history.accident),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiskyBehaviorList(List<RiskyBehaviour> behaviors) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: behaviors.length,
      itemBuilder: (context, index) {
        final behavior = behaviors[index];
        return ListTile(
          leading: _getRiskyBehaviorIcon(behavior.behaviourType),
          title: Text(behavior.behaviourType),
          subtitle: Text(DateFormat('h:mm a').format(behavior.delectedTime)),
          dense: true,
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }

  Widget _buildAccidentList(List<Accident> accidents) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: accidents.length,
      itemBuilder: (context, index) {
        final accident = accidents[index];
        return ListTile(
          leading: const Icon(Icons.car_crash, color: Colors.red),
          title: Text('Accident (${accident.location})'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('h:mm a').format(accident.delectedTime)),
              Text('Emergency Contact: ${accident.contactNum}'),
            ],
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }

  Widget _getRiskyBehaviorIcon(String behaviourType) {
    IconData iconData;
    Color iconColor;

    switch (behaviourType.toLowerCase()) {
      case 'drowsiness':
        iconData = Icons.bedtime_outlined;
        iconColor = Colors.purple;
        break;
      case 'distraction':
        iconData = Icons.phone_android;
        iconColor = Colors.blue;
        break;
      case 'intoxication':
        iconData = Icons.local_bar;
        iconColor = Colors.red;
        break;
      case 'phone usage':
        iconData = Icons.smartphone;
        iconColor = Colors.orange;
        break;
      case 'distress':
        iconData = Icons.sentiment_very_dissatisfied;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.warning_amber;
        iconColor = Colors.amber;
    }

    return Icon(iconData, color: iconColor);
  }
}
