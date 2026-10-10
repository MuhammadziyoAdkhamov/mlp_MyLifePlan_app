import 'package:flutter_test/flutter_test.dart';
import 'package:mylife_plan/services/notification_service.dart';

void main() {
  group('NotificationService.parseTime', () {
    test('parses 12-hour times', () {
      expect(NotificationService.parseTime('2:30 PM'), (14, 30));
      expect(NotificationService.parseTime('12:05 AM'), (0, 5));
      expect(NotificationService.parseTime('12:05 PM'), (12, 5));
    });

    test('parses 24-hour times', () {
      expect(NotificationService.parseTime('14:30'), (14, 30));
      expect(NotificationService.parseTime('00:05'), (0, 5));
      expect(NotificationService.parseTime('23:59'), (23, 59));
    });

    test('rejects out-of-range and malformed times', () {
      expect(NotificationService.parseTime('24:00'), isNull);
      expect(NotificationService.parseTime('12:60 PM'), isNull);
      expect(NotificationService.parseTime('not a time'), isNull);
    });
  });
}
