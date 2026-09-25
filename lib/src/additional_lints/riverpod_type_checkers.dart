import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// TypeChecker for Riverpod Notifier and AsyncNotifier base classes.
const notifierChecker = TypeChecker.any([
  TypeChecker.fromName('Notifier', packageName: 'riverpod'),
  TypeChecker.fromName('AsyncNotifier', packageName: 'riverpod'),
]);

/// TypeChecker for every Riverpod notifier base, including Riverpod 3's
/// `AnyNotifier` that generated `_$Name` classes extend through `$Notifier`.
const anyNotifierChecker = TypeChecker.any([
  TypeChecker.fromName('AnyNotifier', packageName: 'riverpod'),
  notifierChecker,
]);
