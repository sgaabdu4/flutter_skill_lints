import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../ast_node_analysis.dart';

/// Enforces the `flutter_local_notifications` exact-alarm permission API.
class UseLocalNotificationsExactAlarmPermissionApi extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_local_notifications_exact_alarm_permission_api',
    'Use the flutter_local_notifications exact-alarm permission API.',
    correctionMessage:
        'Call AndroidFlutterLocalNotificationsPlugin.requestExactAlarmsPermission(); do not launch android.settings.REQUEST_SCHEDULE_EXACT_ALARM manually.',
    severity: DiagnosticSeverity.ERROR,
  );

  UseLocalNotificationsExactAlarmPermissionApi()
    : super(
        name: 'use_local_notifications_exact_alarm_permission_api',
        description:
            'Avoid manual exact-alarm settings intents when flutter_local_notifications owns the permission flow.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addInstanceCreationExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final UseLocalNotificationsExactAlarmPermissionApi rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!_isAndroidIntent(node)) return;

    final action = _namedArgument(node, 'action');
    if (action == null || !_isExactAlarmSettingsAction(action.expression)) return;

    rule.reportAtNode(action.expression);
  }
}

bool _isAndroidIntent(InstanceCreationExpression node) =>
    node.constructorName.type.name.lexeme == 'AndroidIntent';

NamedExpression? _namedArgument(InstanceCreationExpression node, String name) {
  for (final argument in node.argumentList.arguments) {
    if (argument is NamedExpression && argument.name.lexeme == name) {
      return argument;
    }
  }
  return null;
}

bool _isExactAlarmSettingsAction(Expression expression) {
  final unwrapped = _unwrap(expression);
  return unwrapped is StringLiteral &&
      unwrapped.stringValue == 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM';
}

Expression _unwrap(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }
  return current;
}
