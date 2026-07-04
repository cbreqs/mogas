/// Fiscal year logic for Missouri motor fuel tax refund program.
/// The refund year runs July 1 – June 30.
/// Claims are filed July 1 – September 30 of the following year.
/// 
/// NOTE: Receipt dates are stored as MM/DD/YYYY strings.
class FiscalYear {
  /// The year a fiscal year is identified by (the year it ends).
  /// e.g. FY2026 = July 1, 2025 – June 30, 2026.
  final int year;

  const FiscalYear(this.year);

  /// Returns the fiscal year that is currently relevant:
  /// - During the filing window (July 1 – Sept 30), we are filing for the
  ///   fiscal year that just ended (e.g. in July 2026 → FY2026).
  /// - Outside the filing window, we return the fiscal year currently
  ///   accumulating receipts (e.g. in Oct 2026 → FY2027).
  static FiscalYear get current {
    final now = DateTime.now();
    final month = now.month;
    final year = now.year;

    if (month >= 7 && month <= 9) {
      // Filing window: submitting for the FY that ended June 30 this year
      return FiscalYear(year);
    } else if (month >= 10) {
      // New accumulation period started July 1 — next FY
      return FiscalYear(year + 1);
    } else {
      // Jan–June: still in the FY that ends this June
      return FiscalYear(year);
    }
  }

  /// First day of this fiscal year (July 1 of prior year).
  DateTime get start => DateTime(year - 1, 7, 1);

  /// Last day of this fiscal year (June 30 of the year).
  DateTime get end => DateTime(year, 6, 30, 23, 59, 59);

  /// Human-readable label, e.g. "July 1, 2025 – June 30, 2026"
  String get label => 'July 1, ${year - 1} – June 30, $year';

  /// Short label, e.g. "FY2026"
  String get shortLabel => 'FY$year';

  /// Tax year integer used on the form, e.g. 2026
  int get taxYear => year;

  /// Parses a date string in MM/DD/YYYY or MM-DD-YYYY format to a DateTime.
  /// Also handles 2-digit years (e.g. 10/22/25 → 2025).
  /// Returns null if parsing fails.
  static DateTime? parseDateString(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      // Normalize separators — accept both / and -
      final normalized = dateStr.replaceAll('-', '/');
      final parts = normalized.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        var year = int.parse(parts[2]);
        // Handle 2-digit years: assume 2000s
        if (year < 100) year += 2000;
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  /// Returns true if the given MM/DD/YYYY date string falls within
  /// this fiscal year.
  bool containsDateString(String dateStr) {
    final d = FiscalYear.parseDateString(dateStr);
    if (d == null) return false;
    return !d.isBefore(start) && !d.isAfter(end);
  }

  /// Returns the FY year int for a given MM/DD/YYYY date string.
  /// Returns null if the date cannot be parsed.
  static int? fyYearForDateString(String dateStr) {
    final d = parseDateString(dateStr);
    if (d == null) return null;
    return d.month >= 7 ? d.year + 1 : d.year;
  }

  /// Whether the filing window is currently open (July 1 – Sept 30).
  static bool get isFilingWindowOpen {
    final m = DateTime.now().month;
    return m >= 7 && m <= 9;
  }
}
