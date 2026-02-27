/// Utility class for formatting numbers with Korean number system
class FormatUtils {
  /// Format large numbers using Korean number system
  /// 1000 → 1천, 10000 → 1만, 100000000 → 1억
  ///
  /// Examples:
  /// - 50 → "50"
  /// - 1000 → "1천"
  /// - 5500 → "5.5천"
  /// - 10000 → "1만"
  /// - 50000 → "5만"
  /// - 100000000 → "1억"
  /// - 1234567890 → "12.3억"
  static String formatNumber(int number) {
    if (number < 0) {
      return '-${formatNumber(-number)}';
    }

    // Units in Korean number system
    const units = [
      (value: 100000000, suffix: '억'),      // 100 million
      (value: 10000, suffix: '만'),          // 10 thousand
      (value: 1000, suffix: '천'),           // thousand
    ];

    for (final unit in units) {
      if (number >= unit.value) {
        final quotient = number / unit.value;

        // If it divides evenly or quotient is >= 10, show as integer
        if (quotient % 1 == 0 || quotient >= 10) {
          return '${quotient.toStringAsFixed(0)}${unit.suffix}';
        } else {
          // Show one decimal place for cleaner display
          return '${quotient.toStringAsFixed(1)}${unit.suffix}';
        }
      }
    }

    // For numbers less than 1000, return as is
    return number.toString();
  }

  /// Format number with thousands separator (comma)
  /// Example: 1234567 → "1,234,567"
  static String formatNumberWithComma(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (Match match) => ',',
        );
  }

  /// Format duration from seconds to human readable string
  /// Example: 3661 → "1시간 1분 1초"
  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    final parts = <String>[];
    if (hours > 0) {
      parts.add('$hours시간');
    }
    if (minutes > 0) {
      parts.add('$minutes분');
    }
    if (secs > 0 || parts.isEmpty) {
      parts.add('$secs초');
    }

    return parts.join(' ');
  }

  /// Format duration from milliseconds to human readable string
  static String formatDurationMs(int milliseconds) {
    return formatDuration((milliseconds / 1000).toInt());
  }

  /// Format percentage with one decimal place
  /// Example: 0.5 → "50.0%"
  static String formatPercentage(double percentage) {
    return '${(percentage * 100).toStringAsFixed(1)}%';
  }

  /// Format decimal number to show max N significant figures
  /// Example: formatDecimal(1234.5678, 2) → "1.2e+3"
  /// Example: formatDecimal(0.5, 2) → "0.5"
  static String formatDecimal(double value, {int decimalPlaces = 2}) {
    if (value == 0) {
      return '0';
    }

    // If value is an integer
    if (value == value.toInt()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(decimalPlaces);
  }

  /// Format experience points with Korean suffix
  /// Example: 1000 → "1천 EXP"
  static String formatExp(int exp) {
    return '${formatNumber(exp)} EXP';
  }

  /// Format gold amount with Korean suffix
  /// Example: 1000 → "1천 G"
  static String formatGold(int gold) {
    return '${formatNumber(gold)} G';
  }

  /// Format diamond amount with Korean suffix
  /// Example: 150 → "150 💎"
  static String formatDiamond(int diamond) {
    return '$diamond 💎';
  }

  /// Format short duration (for timers, battles, etc)
  /// Example: 125 → "2분 5초", 5 → "5초"
  static String formatShortDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds초';
    }

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (remainingSeconds == 0) {
      return '$minutes분';
    }

    return '$minutes분 $remainingSeconds초';
  }

  /// Format level with prefix
  /// Example: 50 → "Lv. 50"
  static String formatLevel(int level) {
    return 'Lv. $level';
  }

  /// Format stage with prefix
  /// Example: 25 → "스테이지 25"
  static String formatStage(int stage) {
    return '스테이지 $stage';
  }

  /// Format probability as percentage
  /// Example: 0.6 → "60%", 0.035 → "3.5%"
  static String formatOdds(double odds) {
    final percentage = odds * 100;
    if (percentage % 1 == 0) {
      return '${percentage.toInt()}%';
    }
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Format count with Korean counter unit
  /// Example: 3 → "3마리"
  static String formatMonsterCount(int count) {
    return '$count마리';
  }

  /// Format date as YYYY.MM.DD
  /// Example: DateTime(2026, 2, 27) → "2026.02.27"
  static String formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  /// Format date-time as M/D HH:MM
  /// Example: DateTime(2026, 2, 27, 14, 30) → "2/27 14:30"
  static String formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Format a large number compactly for display in limited space
  /// Example: 1234567 → "1.2M", 1234 → "1.2K"
  static String formatCompact(int number) {
    if (number < 1000) {
      return number.toString();
    }

    if (number < 1000000) {
      final thousands = number / 1000;
      if (thousands % 1 == 0) {
        return '${thousands.toInt()}K';
      }
      return '${thousands.toStringAsFixed(1)}K';
    }

    final millions = number / 1000000;
    if (millions % 1 == 0) {
      return '${millions.toInt()}M';
    }
    return '${millions.toStringAsFixed(1)}M';
  }
}
