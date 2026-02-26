import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/datasources/local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive with Flutter path support
  await Hive.initFlutter();

  // Initialize LocalStorage (registers adapters + opens all boxes)
  await LocalStorage.instance.init();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
