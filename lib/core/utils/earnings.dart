/// Daromad hisob-kitoblari (restoran, magazin, usta, kuryer).
library;

/// Bitta yakunlangan ish: qachon va qancha.
typedef Income = ({DateTime at, int amount});

class EarningsSummary {
  const EarningsSummary({
    required this.today,
    required this.todayCount,
    required this.month,
    required this.monthCount,
    required this.total,
    required this.totalCount,
    required this.daily,
  });

  final int today;
  final int todayCount;

  /// Joriy kalendar oyi.
  final int month;
  final int monthCount;
  final int total;
  final int totalCount;

  /// Eng eskisidan bugungacha, kunma-kun.
  final List<({DateTime day, int amount})> daily;

  factory EarningsSummary.from(
    Iterable<Income> items, {
    required DateTime now,
    int days = 7,
  }) {
    var today = 0, todayCount = 0, month = 0, monthCount = 0;
    var total = 0, totalCount = 0;
    final byDay = <DateTime, int>{
      // DateTime(y, m, d - i) yozgi vaqtga o'tishda ham to'g'ri kun beradi.
      for (var i = days - 1; i >= 0; i--)
        DateTime(now.year, now.month, now.day - i): 0,
    };

    for (final item in items) {
      final day = DateTime(item.at.year, item.at.month, item.at.day);
      total += item.amount;
      totalCount++;
      if (item.at.year == now.year && item.at.month == now.month) {
        month += item.amount;
        monthCount++;
        if (item.at.day == now.day) {
          today += item.amount;
          todayCount++;
        }
      }
      if (byDay.containsKey(day)) byDay[day] = byDay[day]! + item.amount;
    }

    return EarningsSummary(
      today: today,
      todayCount: todayCount,
      month: month,
      monthCount: monthCount,
      total: total,
      totalCount: totalCount,
      daily: [for (final e in byDay.entries) (day: e.key, amount: e.value)],
    );
  }
}
