import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/core/config/app_config.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  throw StateError('AppConfig must be provided during bootstrap.');
});
