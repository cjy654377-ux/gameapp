import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/models/monster_model.dart';
import 'data/models/player_model.dart';
import 'data/models/currency_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive with Flutter path support
  await Hive.initFlutter();

  // Register TypeAdapters
  Hive.registerAdapter(MonsterModelAdapter());  // typeId: 0
  Hive.registerAdapter(PlayerModelAdapter());   // typeId: 1
  Hive.registerAdapter(CurrencyModelAdapter()); // typeId: 2

  // Open boxes
  await Hive.openBox<MonsterModel>('monsters');
  await Hive.openBox<PlayerModel>('player');
  await Hive.openBox<CurrencyModel>('currency');
  await Hive.openBox('settings');

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
