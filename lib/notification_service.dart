import 'dart:math';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  /// Calculates which reminders should show up in the notifications tab today.
  List<Map<String, dynamic>> getDueNotifications(List<dynamic> reminders) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> activeNotifications = [];

    for (var r in reminders) {
      final type = r['type'];
      final isImportant = r['isImportant'] == true;
      DateTime? deadline;

      if (type == 'exam') {
        deadline = DateTime.tryParse(r['examDateTime'] ?? '');
      } else if (type == 'assignment') {
        deadline = DateTime.tryParse(r['submissionDateTime'] ?? '');
      } else if (type == 'general') {
        deadline = DateTime.tryParse(r['toBeDoneBy'] ?? '');
      }

      if (deadline == null) continue;

      final daysUntil = deadline.difference(now).inDays;
      final hoursUntil = deadline.difference(now).inHours;

      // Rule 1: Important notifications send every day once (Random timing simulated by being active all day)
      if (isImportant) {
        activeNotifications.add({
          'reminder': r,
          'message': 'IMPORTANT: ${r['keyword'] ?? 'Task'} is pending!',
          'time': _getRandomTimeLabel(1),
        });
        continue;
      }

      // Rule 2: Exams
      if (type == 'exam') {
        if (daysUntil > 14) {
          // Once a week (We show it if it's exactly 2 weeks or 3 weeks away etc. or just once a week)
          // For the sake of a "Notification Center", we'll show it on specific days of the week (e.g., Monday)
          if (now.weekday == DateTime.monday) {
            activeNotifications.add({
              'reminder': r,
              'message': 'Reminder: Your ${r['subject']} exam is in $daysUntil days.',
              'time': 'Weekly Update',
            });
          }
        } else if (daysUntil <= 14 && daysUntil >= 0) {
          // Less than 2 weeks: 2 times a day
          activeNotifications.add({
            'reminder': r,
            'message': 'Urgent: ${r['subject']} exam is approaching ($daysUntil days left)!',
            'time': 'Morning/Evening',
          });
        }
      }

      // Rule 3: To do by date (General/Assignment) from 3 days before morning evening
      if ((type == 'general' || type == 'assignment') && daysUntil <= 3 && daysUntil >= 0) {
        final title = type == 'assignment' ? r['name'] : (r['keyword'] ?? 'Task');
        activeNotifications.add({
          'reminder': r,
          'message': '$title is due in ${hoursUntil > 24 ? '$daysUntil days' : '$hoursUntil hours'}!',
          'time': 'Morning/Evening',
        });
      }
    }

    return activeNotifications;
  }

  String _getRandomTimeLabel(int frequency) {
    if (frequency == 1) {
      final hours = [9, 14, 18, 21];
      return 'Scheduled: ${hours[Random().nextInt(hours.length)]}:00';
    }
    return 'Morning & Evening';
  }
}
