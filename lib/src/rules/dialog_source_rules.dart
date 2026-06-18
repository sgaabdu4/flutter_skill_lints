import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> dialogSourceRules = [
  /// Dialogs and sheets must not subscribe to the provider their own action mutates.
  ///
  /// Why: A modal route stays mounted for the entire dismiss animation. If the
  /// dialog widget watches state that its button callback mutates, the dialog
  /// rebuilds mid-dismiss against now-stale state and visibly flips its variant.
  /// Pass an immutable snapshot value object through the constructor instead.
  scannerRule(
    code: const LintCode(
      'dialog_widget_subscribes_to_mutable_provider',
      'Dialog/sheet widget watches a provider its own action also mutates.',
      correctionMessage:
          'Pass an immutable snapshot value object via the constructor. The dialog must not subscribe to state its own action mutates.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags dialog/sheet widgets that ref.watch and ref.read(...notifier).<method>() on the same provider so the Flutter skill modal snapshot pattern is shown during analysis.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        if (!_isDialogHostClass(context, classSpan)) continue;
        if (!_extendsConsumerSurface(context, classSpan)) continue;

        final mutated = <String>{};
        for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
          final line = context.source.masked[i];
          for (final match in _refReadNotifierMethod.allMatches(line)) {
            final provider = match.group(1);
            if (provider != null && provider.isNotEmpty) mutated.add(provider);
          }
        }
        if (mutated.isEmpty) continue;

        for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
          final line = context.source.masked[i];
          for (final match in _refWatchProvider.allMatches(line)) {
            final provider = match.group(1) ?? '';
            if (!mutated.contains(provider)) continue;
            if (_lineIgnoresRule(context, i, 'dialog_widget_subscribes_to_mutable_provider')) {
              break;
            }
            reporter.report(context, i, match.start);
            break;
          }
        }
      }
    },
  ),

  /// Modal parent widgets must not watch high-frequency provider fields.
  ///
  /// Why: A sheet/dialog parent often owns text fields, scroll views, and other
  /// large subtrees. Watching timer/ticker/progress fields there rebuilds the
  /// whole modal every tick. Extract the ticking controls to a leaf
  /// ConsumerWidget and watch the high-frequency field in that leaf only.
  scannerRule(
    code: const LintCode(
      'modal_high_frequency_watch_not_leaf',
      'Modal parent watches a high-frequency provider field.',
      correctionMessage:
          'Extract the ticking/progress controls to a leaf ConsumerWidget and watch seconds/progress/isRunning there instead of in the sheet/dialog parent.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags dialog/sheet classes that watch timer, ticker, progress, or running-state provider fields in build().',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        if (!_isDialogHostClass(context, classSpan)) continue;
        if (!_extendsConsumerSurface(context, classSpan)) continue;
        for (final method in context.methods.where((m) => m.name == 'build')) {
          if (!classSpan.contains(method.start)) continue;
          for (var i = method.start; i <= method.end && i < context.source.length; i++) {
            final line = context.source.masked[i];
            final watchStart = line.indexOf('ref.watch');
            if (watchStart < 0) continue;
            final watchWindow = _collectLineWindow(context, i, method.end, 8);
            if (!_highFrequencyWatch.hasMatch(watchWindow)) continue;
            if (_lineIgnoresRule(context, i, 'modal_high_frequency_watch_not_leaf')) continue;
            reporter.report(context, i, watchStart);
          }
        }
      }
    },
  ),

  /// Dialog button callbacks must pop with a result, not chain side effects.
  ///
  /// Why: Code after Navigator.pop runs against a dying widget tree — the
  /// dismiss animation has started, context.mounted will flip to false mid-flight,
  /// and any provider mutation triggers a rebuild on the disappearing dialog.
  /// Let the caller orchestrate side effects after `await showDialog<T>(...)`.
  scannerRule(
    code: const LintCode(
      'dialog_button_pop_then_state_mutation',
      'Dialog button mutates state or navigates after Navigator.pop.',
      correctionMessage:
          'Dialogs must Navigator.pop(result) and exit. Move provider mutations or further navigation to the caller after `await showDialog<T>(...)`.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags code that runs after Navigator.pop inside a dialog/sheet widget so the modal snapshot pattern is shown during analysis.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        if (!_isDialogHostClass(context, classSpan)) continue;

        var inBody = false;
        var depth = 0;
        var popLine = -1;
        var popDepth = -1;
        for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
          final line = context.source.masked[i];
          if (!inBody && line.contains('{')) inBody = true;

          if (popLine >= 0 && i > popLine) {
            final offender = _postPopOffender.firstMatch(line);
            if (offender != null) {
              reporter.report(context, i, offender.start);
              popLine = -1;
              popDepth = -1;
            }
          }

          if (_popInvocation.hasMatch(line)) {
            popLine = i;
            popDepth = depth;
          }

          depth += _braceDelta(line);
          if (popLine >= 0 && depth < popDepth) {
            popLine = -1;
            popDepth = -1;
          }
        }
      }
    },
  ),

  /// `select` records that read Map/Set/List getters notify on every parent change.
  ///
  /// Why: Records compare by field identity. A getter that builds a fresh Map,
  /// Set, or List per access produces a new identity on every read, so the
  /// record `==` is always false and the watcher rebuilds even when no relevant
  /// field changed. Watch primitive fields or memoize the derived value in a
  /// provider.
  scannerRule(
    code: const LintCode(
      'select_returns_unstable_record_identity',
      'Record select includes a getter that returns a fresh Map/Set/List each call.',
      correctionMessage:
          'Records compare by field identity; getters that build a fresh Map/Set/List each call cause a rebuild on every notify. Watch primitive fields or memoize the derived value in a provider.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags ref.watch(...select((s) => (...record literal...))) where any field reads a getter whose name implies a fresh Map/Set/List per call.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final selectMatch = _selectRecordStart.firstMatch(line);
        if (selectMatch == null) continue;

        final window = StringBuffer(line);
        final end = (i + 6 > context.source.length) ? context.source.length : i + 6;
        for (var j = i + 1; j < end; j++) {
          window.write('\n');
          window.write(context.source.masked[j]);
        }
        final body = window.toString();
        if (!_unstableGetterField.hasMatch(body)) continue;
        reporter.report(context, i, line.indexOf('.select'));
      }
    },
  ),

  /// `build` must be pure. Do not assign to fields from inside build.
  ///
  /// Why: `build` may run any number of times for any reason. Caching a derived
  /// value in `_field ??= compute()` makes the widget retain stale data across
  /// the next provider invalidation and turns rebuilds into ordering-dependent
  /// state mutations. Compute the value in an event callback or expose it via
  /// a provider.
  scannerRule(
    code: const LintCode(
      'build_method_assigns_to_field',
      'build() must not assign to a field.',
      correctionMessage:
          'build must be pure. Move the assignment to initState, an event callback, or a provider.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags field assignments inside build methods so widget builds stay pure and idempotent.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final method in context.methods.where((m) => m.name == 'build')) {
        for (var i = method.start + 1; i <= method.end && i < context.source.length; i++) {
          final line = context.source.masked[i];
          final match = _buildFieldAssignment.firstMatch(line);
          if (match == null) continue;
          if (_isInsideFunctionLiteral(context, method.start, i, match.start)) {
            continue;
          }
          reporter.report(context, i, line.length - line.trimLeft().length);
        }
      }
    },
  ),

  /// `build` must not call helpers that mutate instance state.
  ///
  /// Why: Moving field/controller writes into `_sync...()` or `_load...()` keeps
  /// the assignment out of sight but still makes build impure. `build` can run
  /// any time; a helper that writes fields, controller text/value, or calls
  /// `setState` turns rebuilds into state mutations.
  scannerRule(
    code: const LintCode(
      'build_calls_mutating_instance_method',
      'build() calls a helper that mutates instance state.',
      correctionMessage:
          'Keep build pure. Move field/controller sync to initState, didUpdateWidget, an event callback, or a provider.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags build() calls to private methods that assign instance fields/controller properties or call setState.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        final mutatingMethods = _mutatingPrivateMethods(context, classSpan);
        if (mutatingMethods.isEmpty) continue;
        for (final method in context.methods.where((m) => m.name == 'build')) {
          if (!classSpan.contains(method.start)) continue;
          for (var i = method.start + 1; i <= method.end && i < context.source.length; i++) {
            final line = context.source.masked[i];
            for (final mutatingMethod in mutatingMethods) {
              final match = RegExp(
                r'\b' + RegExp.escape(mutatingMethod) + r'\s*\(',
              ).firstMatch(line);
              if (match == null) continue;
              if (_isInsideFunctionLiteral(context, method.start, i, match.start)) continue;
              reporter.report(context, i, match.start);
              break;
            }
          }
        }
      }
    },
  ),

  /// State teardown belongs in the notifier, not in a widget callback after await.
  ///
  /// Why: When a widget awaits a notifier mutation and then calls reset/clear,
  /// the same mutation may have triggered a parent rebuild that unmounted the
  /// widget. context.mounted goes false, the teardown is skipped, and the
  /// screen never sees the cleared state. Make the notifier method own its
  /// own teardown on the success path.
  scannerRule(
    code: const LintCode(
      'widget_calls_notifier_teardown_after_await',
      'Widget calls notifier.reset/clear/dispose after awaiting a notifier mutation.',
      correctionMessage:
          'Move the teardown into the notifier method on its success path. Widgets dispatch and observe state; they do not orchestrate notifier lifecycle.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags reset/clear/dispose calls that follow an awaited notifier mutation in non-notifier files so the notifier owns its own teardown.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        if (classSpan.isNotifier) continue;
        if (!_extendsWidgetSurface(context, classSpan)) continue;

        final awaitedProviders = <String, int>{};
        var depth = 0;
        for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
          final line = context.source.masked[i];

          final awaited = _awaitedNotifierMethod.firstMatch(line);
          if (awaited != null) {
            final provider = awaited.group(1) ?? '';
            if (provider.isNotEmpty) awaitedProviders[provider] = depth;
          }

          if (awaitedProviders.isNotEmpty) {
            for (final match in _notifierTeardown.allMatches(line)) {
              final provider = match.group(1) ?? '';
              if (!awaitedProviders.containsKey(provider)) continue;
              reporter.report(context, i, match.start);
            }
          }

          depth += _braceDelta(line);
          awaitedProviders.removeWhere((_, recordedDepth) => depth < recordedDepth);
        }
      }
    },
  ),

  /// After awaiting a modal, use a typed route .go(context), not pop navigation.
  ///
  /// Why: A screen that protects accidental exit with `PopScope(canPop: false)`
  /// intercepts every programmatic pop, including pop-fallback helpers, and
  /// flashes its own confirm-exit dialog. Use a typed `<Route>().go(context)`
  /// (or `context.go(...)`) which bypasses the local pop interceptor.
  scannerRule(
    code: const LintCode(
      'popscope_bypass_uses_go_not_pop',
      'Pop navigation after an awaited modal triggers PopScope interception.',
      correctionMessage:
          'Use a typed `<Route>().go(context)` (or `context.go(...)`) for intentional navigation after an awaited modal; pop navigation triggers PopScope.onPopInvoked.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags context.pop* calls that follow an awaited modal helper inside the same method.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        final modalDepths = <int>{};
        var depth = 0;
        for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
          final line = context.source.masked[i];
          if (_awaitModalCall.hasMatch(line)) modalDepths.add(depth);
          if (modalDepths.isNotEmpty) {
            final match = _popNavigationCall.firstMatch(line);
            if (match != null) {
              reporter.report(context, i, match.start);
            }
          }
          depth += _braceDelta(line);
          modalDepths.removeWhere((d) => depth < d);
        }
      }
    },
  ),

  /// `showDialog` / `showModalBottomSheet` must carry `routeSettings`.
  ///
  /// Why: Without a route name, the dialog/sheet route does not appear in
  /// observer logs, analytics, or `GoRouter` debug output as anything other
  /// than `?`. Pass `routeSettings: const RouteSettings(name: '<feature>-<intent>')`
  /// at every call site (including app-wide wrappers like `showAppDialog` /
  /// `showAppBottomSheet`).
  scannerRule(
    code: const LintCode(
      'modal_helper_requires_route_settings',
      'show modal helper missing routeSettings.',
      correctionMessage:
          'Pass `routeSettings: const RouteSettings(name: "...")` so the dialog/sheet shows up in observer logs and analytics.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Flags showDialog/showModalBottomSheet calls without a routeSettings argument.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final match = _showModalCall.firstMatch(line);
        if (match == null) continue;
        final args = _collectArgList(context, i, match.end);
        if (args == null) continue;
        if (_routeSettingsArg.hasMatch(args)) continue;
        reporter.report(context, i, match.start);
      }
    },
  ),
];

final _showModalCall = RegExp(
  r'\b(?:show(?:Dialog|ModalBottomSheet)|show[A-Z]\w*(?:Dialog|Sheet|BottomSheet))'
  r'(?:\s*<[^>]*>)?\s*\(',
);

final _routeSettingsArg = RegExp(r'\brouteSettings\s*:');

String _collectLineWindow(SourceScannerContext context, int startLine, int endLine, int maxLines) {
  final end = startLine + maxLines > endLine ? endLine : startLine + maxLines;
  final buffer = StringBuffer();
  for (var i = startLine; i <= end && i < context.source.length; i++) {
    if (i > startLine) buffer.write('\n');
    buffer.write(context.source.masked[i]);
  }
  return buffer.toString();
}

String? _collectArgList(SourceScannerContext context, int startLine, int startCol) {
  final buffer = StringBuffer();
  var depth = 0;
  var sawOpen = false;
  for (var i = startLine; i < context.source.length && i < startLine + 40; i++) {
    final line = context.source.masked[i];
    final from = i == startLine ? startCol - 1 : 0;
    for (var j = from < 0 ? 0 : from; j < line.length; j++) {
      final ch = line[j];
      if (ch == '(') {
        depth++;
        sawOpen = true;
      } else if (ch == ')') {
        depth--;
        if (sawOpen && depth == 0) return buffer.toString();
      }
      if (sawOpen) buffer.write(ch);
    }
    buffer.write('\n');
  }
  return null;
}

// ---------------------------------------------------------------------------
// Shared regex patterns and helpers
// ---------------------------------------------------------------------------

final _refReadNotifierMethod = RegExp(
  r'\bref\s*\.\s*read\s*\(\s*([A-Za-z_]\w*)\b[^)]*\.\s*notifier\s*\)',
);

final _refWatchProvider = RegExp(r'\bref\s*\.\s*watch\s*\(\s*([A-Za-z_]\w*)\b');

final _highFrequencyWatch = RegExp(
  r'\bref\s*\.\s*watch\s*\([\s\S]*?\.\s*select\s*\(\s*'
  r'(?:\([A-Za-z_]\w*\)|[A-Za-z_]\w*)\s*=>\s*[A-Za-z_]\w*\s*\.\s*'
  r'(?:seconds|elapsed|elapsedSeconds|tick|ticks|progress|percent|isRunning|isAnimating|isPlaying)\b',
);

final _popInvocation = RegExp(
  r'\b(?:Navigator\s*\.\s*(?:of\s*\([^)]*\)\s*\.\s*)?(?:pop|maybePop)|context\s*\.\s*pop[A-Za-z_]*)\s*\(',
);

final _postPopOffender = RegExp(
  r'\b(?:ref\s*\.\s*(?:read|watch|invalidate|refresh)\s*\(|'
  r'context\s*\.\s*(?:go|push|replace|goNamed|pushNamed|replaceNamed)\b|'
  r'Navigator\s*\.\s*(?:of\s*\([^)]*\)\s*\.\s*)?(?:push|pushNamed|pushReplacement|pushReplacementNamed)\s*\(|'
  r'\b[A-Z]\w*Route\s*\([^)]*\)\s*\.\s*go\s*\()',
);

final _selectRecordStart = RegExp(
  r'\bref\s*\.\s*watch\s*\([^)]*\.\s*select\s*\(\s*\([A-Za-z_]\w*\)\s*=>\s*\(',
);

final _unstableGetterField = RegExp(
  r'[A-Za-z_]\w*\s*:\s*[A-Za-z_]\w*\s*\.\s*'
  r'([A-Za-z_]\w*(?:Map|Set|Sets|Ids|Items|Entries|sBy[A-Z]\w*|By[A-Z]\w*))\b',
);

final _buildFieldAssignment = RegExp(
  r'^\s*(?:this\s*\.\s*[A-Za-z_]\w*|_[A-Za-z]\w*)\s*(?:\?\?=|=(?![=>]))',
);

final _instanceStateMutation = RegExp(
  r'^\s*(?:this\s*\.\s*)?_[A-Za-z]\w*(?:\s*(?:\?\?=|=(?![=>]))|\s*\.\s*[A-Za-z_]\w*\s*=(?![=>]))|\bsetState\s*\(',
);

final _functionLiteralOpen = RegExp(
  r'(?:^\s*|[:=,(]\s*)(?:\([^)]*\)|[A-Za-z_]\w*)\s*(?:async\s*)?\{',
);

final _awaitedNotifierMethod = RegExp(
  r'\bawait\s+ref\s*\.\s*read\s*\(\s*([A-Za-z_]\w*)\b[^)]*\.\s*notifier\s*\)\s*\.\s*[A-Za-z_]\w*\s*\(',
);

final _notifierTeardown = RegExp(
  r'\bref\s*\.\s*read\s*\(\s*([A-Za-z_]\w*)\b[^)]*\.\s*notifier\s*\)\s*\.\s*(?:reset|clear|dispose)\s*\(',
);

final _awaitModalCall = RegExp(
  r'\bawait\s+(?:\w+\s*\.\s*)?'
  r'(?:show(?:Dialog|ModalBottomSheet)|show[A-Z]\w*(?:Dialog|Sheet|BottomSheet))\b',
);

final _popNavigationCall = RegExp(r'\bcontext\s*\.\s*pop[A-Za-z_]*\s*\(');

bool _isDialogHostClass(SourceScannerContext context, ScannerClassSpan classSpan) {
  if (_classNameLooksLikeDialog(classSpan.name)) return true;
  final path = context.path.toLowerCase();
  return path.endsWith('_dialog.dart') ||
      path.endsWith('_sheet.dart') ||
      path.endsWith('_bottom_sheet.dart') ||
      path.endsWith('_dialog_content.dart') ||
      path.endsWith('_sheet_content.dart');
}

bool _classNameLooksLikeDialog(String name) {
  return name.endsWith('Dialog') ||
      name.endsWith('DialogContent') ||
      name.endsWith('Sheet') ||
      name.endsWith('SheetContent') ||
      name.endsWith('BottomSheet');
}

bool _extendsConsumerSurface(SourceScannerContext context, ScannerClassSpan classSpan) {
  final signature = _classSignature(context, classSpan);
  return _consumerSurface.hasMatch(signature);
}

bool _extendsWidgetSurface(SourceScannerContext context, ScannerClassSpan classSpan) {
  final signature = _classSignature(context, classSpan);
  return _widgetSurface.hasMatch(signature);
}

final _consumerSurface = RegExp(
  r'\bextends\s+(?:ConsumerWidget|ConsumerStatefulWidget|HookConsumerWidget|ConsumerState\b|HookConsumerState\b)',
);

final _widgetSurface = RegExp(
  r'\bextends\s+(?:ConsumerWidget|ConsumerStatefulWidget|HookConsumerWidget|StatelessWidget|StatefulWidget|HookWidget|ConsumerState\b|HookConsumerState\b|State\s*<)',
);

String _classSignature(SourceScannerContext context, ScannerClassSpan classSpan) {
  final buffer = StringBuffer();
  for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
    final line = context.source.masked[i];
    buffer.write(' ');
    buffer.write(line);
    if (line.contains('{')) break;
  }
  return buffer.toString();
}

Set<String> _mutatingPrivateMethods(SourceScannerContext context, ScannerClassSpan classSpan) {
  final names = <String>{};
  for (final method in context.methods) {
    if (!classSpan.contains(method.start)) continue;
    if (!method.name.startsWith('_')) continue;
    if (method.name == '_debugFillProperties') continue;
    for (var i = method.start + 1; i <= method.end && i < context.source.length; i++) {
      if (!_instanceStateMutation.hasMatch(context.source.masked[i])) continue;
      names.add(method.name);
      break;
    }
  }
  return names;
}

bool _lineIgnoresRule(SourceScannerContext context, int lineIndex, String ruleName) {
  final pattern = RegExp(r'//\s*ignore(?:_for_file)?\s*:\s*([^\n]+)');
  for (final i in [lineIndex, lineIndex - 1]) {
    if (i < 0 || i >= context.source.length) continue;
    final match = pattern.firstMatch(context.source.original[i]);
    if (match == null) continue;
    final codes = match.group(1)?.split(',').map((c) => c.trim()).toSet() ?? const {};
    if (codes.contains(ruleName)) return true;
  }
  for (var i = 0; i < context.source.length && i < 20; i++) {
    final match = RegExp(
      r'//\s*ignore_for_file\s*:\s*([^\n]+)',
    ).firstMatch(context.source.original[i]);
    if (match == null) continue;
    final codes = match.group(1)?.split(',').map((c) => c.trim()).toSet() ?? const {};
    if (codes.contains(ruleName)) return true;
  }
  return false;
}

int _braceDelta(String line) {
  var delta = 0;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '{') {
      delta++;
    } else if (char == '}') {
      delta--;
    }
  }
  return delta;
}

bool _isInsideFunctionLiteral(
  SourceScannerContext context,
  int methodStart,
  int lineIndex,
  int column,
) {
  var closureDepth = 0;
  for (var i = methodStart + 1; i <= lineIndex && i < context.source.length; i++) {
    final line = context.source.masked[i];
    if (i == lineIndex) {
      if (closureDepth > 0) return true;
      final safeColumn = column < 0 ? 0 : (column > line.length ? line.length : column);
      final prefix = line.substring(0, safeColumn);
      return _functionLiteralOpen.hasMatch(prefix);
    }
    final delta = _braceDelta(line);
    if (_functionLiteralOpen.hasMatch(line) && delta > 0) {
      closureDepth += delta;
    } else if (closureDepth > 0) {
      closureDepth += delta;
      if (closureDepth < 0) closureDepth = 0;
    }
  }
  return false;
}
