import 'package:flutter/material.dart';

import 'app.dart';
import 'services/adventure_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdventureNotificationService.initialize();
  runApp(const RushForVilliansApp());
}
