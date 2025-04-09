import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:drivesense/ui/alert_notification/view_model/alert_view_model.dart';
import 'package:drivesense/ui/core/widgets/app_bottom_navbar.dart';

final List<Map<String, dynamic>> alertMethods = [
  {'name': 'Alarm (Default)', 'hasExtraConfig': false},
  {'name': 'Audio', 'hasExtraConfig': true},
  {'name': 'Self-Configured Audio', 'hasExtraConfig': true},
  {'name': 'Music', 'hasExtraConfig': true},
  {'name': 'AI Chatbot', 'hasExtraConfig': false},
];

class ManageAlertView extends StatefulWidget {
  const ManageAlertView({super.key});

  @override
  State<ManageAlertView> createState() => _ManageAlertViewState();
}

class _ManageAlertViewState extends State<ManageAlertView> {
  @override
  void initState() {
    super.initState();
    Provider.of<AlertViewModel>(context, listen: false).loadAlertData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Alert Method',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alert',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                _buildAlertMethodsList(viewModel),
              ],
            ),
          ),
          bottomNavigationBar: const AppBottomNavBar(
            currentRoute: '/manage_alert',
          ),
        );
      },
    );
  }
}

Widget _buildAlertMethodsList(AlertViewModel viewModel) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1A237E),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: alertMethods.length,
      itemBuilder: (context, index) {
        final alert = alertMethods[index];
        var isSelected =
            alert['name'] ==
            viewModel
                .alert
                .alertTypeName; //TODO: might need to change var to final or ?

        return Container(
          decoration: BoxDecoration(
            border:
                index != alertMethods.length - 1
                    ? const Border(
                      bottom: BorderSide(color: Colors.white24, width: 0.5),
                    )
                    : null,
          ),
          child: ListTile(
            title: Text(
              alert['name'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
            onTap: () {
              viewModel.updateAlert(alert['name']).then((success) {
                if (success) {
                  isSelected =
                      alert['name'] ==
                      viewModel.alert.alertTypeName; //TODO: maybe not needed
                }
              });
            },
            leading: Icon(
              Icons.check,
              color: isSelected ? Colors.blue : Colors.transparent,
            ),
            trailing:
                alert['hasExtraConfig']
                    ? IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        print('Navigating to extra config for ${alert['name']}');
                        context.go(
                          '/extra_config/?alertTypeName=${alert['name']}',
                        );
                      },
                    )
                    : null,
          ),
        );
      },
    ),
  );
}
