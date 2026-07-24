import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

class UpdateChecker extends StatelessWidget {
  final Widget child;

  const UpdateChecker({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      dialogStyle: UpgradeDialogStyle.cupertino,
      showIgnore: true,
      showLater: true,
      upgrader: Upgrader(
        durationUntilAlertAgain: const Duration(seconds: 1),
        messages: UpgraderMessages(code: 'tr'),
      ),
      child: child,
    );
  }
}
