import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the game has completed its initialization sequence.
///
/// Set to `true` after [LocalStorage.init()] and initial data loading are done.
/// Widgets can watch this provider and show a loading screen until it is true.
final gameInitializedProvider = StateProvider<bool>((ref) => false);
