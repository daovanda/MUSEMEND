import 'package:flutter/widgets.dart';
import 'package:musemend/bootstrap.dart';
import 'package:musemend/core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap(AppConfig.fromEnvironment());
}
