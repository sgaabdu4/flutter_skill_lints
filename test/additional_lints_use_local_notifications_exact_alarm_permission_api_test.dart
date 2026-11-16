import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_local_notifications_exact_alarm_permission_api.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<UseLocalNotificationsExactAlarmPermissionApiTest>(
    'UseLocalNotificationsExactAlarmPermissionApiTest',
    UseLocalNotificationsExactAlarmPermissionApiTest.new,
    {
      'test_androidIntentExactAlarmSettingsAction_lint': (t) =>
          t._androidIntentExactAlarmSettingsActionLint(),
      'test_androidIntentOtherSettingsAction_noLint': (t) =>
          t._androidIntentOtherSettingsActionNoLint(),
      'test_exactAlarmPermissionApi_noLint': (t) => t._exactAlarmPermissionApiNoLint(),
      'test_exactAlarmSettingsStringWithoutAndroidIntent_noLint': (t) =>
          t._exactAlarmSettingsStringWithoutAndroidIntentNoLint(),
    },
  );
}

class UseLocalNotificationsExactAlarmPermissionApiTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseLocalNotificationsExactAlarmPermissionApi();
    super.setUp();
  }

  T lintFor<T>(String source, String needle) {
    final offset = source.indexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    return lint(offset, needle.length) as T;
  }

  Future<void> _androidIntentExactAlarmSettingsActionLint() async {
    const source = r'''
class AndroidIntent {
  const AndroidIntent({required String action});
}

void requestPermission() {
  const intent = AndroidIntent(action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM');
  intent.toString();
}
''';

    await assertDiagnostics(source, [
      lintFor(source, "'android.settings.REQUEST_SCHEDULE_EXACT_ALARM'"),
    ]);
  }

  Future<void> _androidIntentOtherSettingsActionNoLint() async {
    await assertNoDiagnostics(r'''
class AndroidIntent {
  const AndroidIntent({required String action});
}

void openSettings() {
  const intent = AndroidIntent(action: 'android.settings.APPLICATION_DETAILS_SETTINGS');
  intent.toString();
}
''');
  }

  Future<void> _exactAlarmPermissionApiNoLint() async {
    await assertNoDiagnostics(r'''
class AndroidFlutterLocalNotificationsPlugin {
  Future<bool?> canScheduleExactNotifications() async => true;
  Future<bool?> requestExactAlarmsPermission() async => true;
}

Future<bool> requestPermission(AndroidFlutterLocalNotificationsPlugin android) async {
  final canSchedule = await android.canScheduleExactNotifications();
  if (canSchedule == true) return true;

  final granted = await android.requestExactAlarmsPermission();
  return granted == true;
}
''');
  }

  Future<void> _exactAlarmSettingsStringWithoutAndroidIntentNoLint() async {
    await assertNoDiagnostics(r'''
const exactAlarmSettingsAction = 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM';
''');
  }
}
