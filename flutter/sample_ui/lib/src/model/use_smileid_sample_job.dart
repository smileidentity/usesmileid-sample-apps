import 'use_smileid_sample_product.dart';
import 'use_smileid_sample_status.dart';

/// One verification the app has run, as the list and the detail page show it.
class UseSmileIDSampleJob {
  /// [createdAtMillis] is absolute; a countdown is never stored, only a deadline (R6).
  const UseSmileIDSampleJob({
    required this.id,
    required this.userId,
    required this.product,
    required this.status,
    required this.createdAtMillis,
    this.message = '',
    this.httpStatus,
    this.sandbox = true,
    this.sessionId,
    this.partnerId,
  });

  /// Rebuilds a row read back from storage, resolving both enums by lookup so a rename cannot crash a restore.
  static UseSmileIDSampleJob? fromStored(Map<String, Object?> json) {
    final Object? id = json['id'];
    // The one field with no sensible substitute: a row nothing can address is not a row.
    if (id is! String || id.isEmpty) {
      return null;
    }
    return UseSmileIDSampleJob(
      id: id,
      userId: json['userId'] is String ? json['userId']! as String : '',
      product: _productNamed(json['product']),
      status: _statusNamed(json['status']),
      createdAtMillis: json['createdAtMillis'] is int
          ? json['createdAtMillis']! as int
          : 0,
      message: json['message'] is String ? json['message']! as String : '',
      httpStatus: json['httpStatus'] is int ? json['httpStatus']! as int : null,
      sandbox: json['sandbox'] != false,
      sessionId: json['sessionId'] is String
          ? json['sessionId']! as String
          : null,
      partnerId: json['partnerId'] is String
          ? json['partnerId']! as String
          : null,
    );
  }

  /// The job id the API returned.
  final String id;

  /// The user id the job ran under.
  final String userId;

  /// Which product produced it.
  final UseSmileIDSampleProduct product;

  /// The verdict, which is what the badge and the filters read.
  final UseSmileIDSampleStatus status;

  /// When it was submitted.
  final int createdAtMillis;

  /// The server's own words, shown on the detail page rather than in the list.
  final String message;

  /// The HTTP outcome, which is not the verdict; null when the job never reached the API.
  final int? httpStatus;

  /// Whether it ran against sandbox.
  final bool sandbox;

  /// The token session it ran under, absent on a fixture.
  final String? sessionId;

  /// The partner it ran under, absent on a fixture.
  final String? partnerId;

  /// The same row carrying a refreshed verdict; every other field is what the run recorded.
  UseSmileIDSampleJob withStatus({
    required UseSmileIDSampleStatus status,
    required String message,
    required int httpStatus,
  }) => UseSmileIDSampleJob(
    id: id,
    userId: userId,
    product: product,
    status: status,
    createdAtMillis: createdAtMillis,
    message: message,
    httpStatus: httpStatus,
    sandbox: sandbox,
    sessionId: sessionId,
    partnerId: partnerId,
  );

  /// The id as a row shows it.
  String get shortId => _elide(id);

  /// The user id as the detail page shows it.
  String get shortUserId => _elide(userId);

  /// The submission instant, as the detail page shows it: ISO 8601 in UTC, to the millisecond.
  String get createdAtLabel {
    final DateTime at = DateTime.fromMillisecondsSinceEpoch(
      createdAtMillis,
      isUtc: true,
    );
    String pad(int value, int width) => value.toString().padLeft(width, '0');
    return '${at.year}-${pad(at.month, 2)}-${pad(at.day, 2)}'
        'T${pad(at.hour, 2)}:${pad(at.minute, 2)}:${pad(at.second, 2)}'
        '.${pad(at.millisecond, 3)}Z';
  }

  /// The TRANSPORT outcome, which is not the verdict: a 202 means accepted, not cleared.
  String get httpStatusLabel => switch (httpStatus) {
    null => '',
    200 => '200 OK',
    202 => '202 Accepted',
    final int code => '$code',
  };

  /// Whether the transport succeeded, which is what colours the status row.
  bool? get httpSucceeded =>
      httpStatus == null ? null : httpStatus! >= 200 && httpStatus! < 300;

  /// What the store writes.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'userId': userId,
    'product': product.name,
    'status': status.name,
    'createdAtMillis': createdAtMillis,
    'message': message,
    'httpStatus': httpStatus,
    'sandbox': sandbox,
    'sessionId': sessionId,
    'partnerId': partnerId,
  };
}

/// A stored product name, substituting the first as Android and iOS do rather than dropping the row.
UseSmileIDSampleProduct _productNamed(Object? name) {
  for (final UseSmileIDSampleProduct product
      in UseSmileIDSampleProduct.values) {
    if (product.name == name) {
      return product;
    }
  }
  return UseSmileIDSampleProduct.values.first;
}

/// A stored status name, substituting Processing as Android and iOS do.
UseSmileIDSampleStatus _statusNamed(Object? name) {
  for (final UseSmileIDSampleStatus status in UseSmileIDSampleStatus.values) {
    if (status.name == name) {
      return status;
    }
  }
  return UseSmileIDSampleStatus.processing;
}

/// The chips above the list, in the order they are drawn. There is deliberately no Processing chip:
/// a fourth chip would be a filter the design does not have.
enum UseSmileIDSampleJobFilter {
  /// Everything.
  all('all', 'All', null),

  /// Cleared only.
  clear('clear', 'Clear', UseSmileIDSampleStatus.clear),

  /// Needs attention only.
  attention('attention', 'Attention', UseSmileIDSampleStatus.attention),

  /// Blocked only.
  blocked('blocked', 'Blocked', UseSmileIDSampleStatus.blocked);

  const UseSmileIDSampleJobFilter(this.id, this.label, this.status);

  /// The id that suffixes this chip's test ids.
  final String id;

  /// The chip's text.
  final String label;

  /// The status this chip keeps, null for All.
  final UseSmileIDSampleStatus? status;

  /// Whether [job] belongs under this chip.
  bool matches(UseSmileIDSampleJob job) =>
      status == null || job.status == status;
}

/// One calendar day's worth of jobs, newest day first.
class UseSmileIDSampleJobDay {
  /// [startMillis] is local midnight, which is what the header is derived from.
  const UseSmileIDSampleJobDay({required this.startMillis, required this.jobs});

  /// Local midnight of the day these jobs fall on.
  final int startMillis;

  /// The day's jobs, newest first.
  final List<UseSmileIDSampleJob> jobs;
}

/// Groups [jobs] by local day, newest job and newest day first.
List<UseSmileIDSampleJobDay> useSmileIDSampleGroupByDay(
  List<UseSmileIDSampleJob> jobs,
) {
  final List<UseSmileIDSampleJob> sorted = List<UseSmileIDSampleJob>.of(jobs)
    ..sort(
      (UseSmileIDSampleJob a, UseSmileIDSampleJob b) =>
          b.createdAtMillis.compareTo(a.createdAtMillis),
    );
  final List<int> starts = <int>[];
  final Map<int, List<UseSmileIDSampleJob>> byDay =
      <int, List<UseSmileIDSampleJob>>{};
  for (final UseSmileIDSampleJob job in sorted) {
    final int start = useSmileIDSampleStartOfDayMillis(job.createdAtMillis);
    final List<UseSmileIDSampleJob> day = byDay.putIfAbsent(start, () {
      starts.add(start);
      return <UseSmileIDSampleJob>[];
    });
    day.add(job);
  }
  return <UseSmileIDSampleJobDay>[
    for (final int start in starts)
      UseSmileIDSampleJobDay(
        startMillis: start,
        jobs: List<UseSmileIDSampleJob>.unmodifiable(byDay[start]!),
      ),
  ];
}

/// Local midnight of the day [millis] falls on.
int useSmileIDSampleStartOfDayMillis(int millis) {
  final DateTime at = DateTime.fromMillisecondsSinceEpoch(millis);
  return DateTime(at.year, at.month, at.day).millisecondsSinceEpoch;
}

/// TODAY, YESTERDAY, or empty for a day older than that, against [nowMillis].
String useSmileIDSampleRelativeDay(int dayStartMillis, int nowMillis) {
  final int today = useSmileIDSampleStartOfDayMillis(nowMillis);
  if (dayStartMillis == today) {
    return 'TODAY';
  }
  // Calendar arithmetic, not a fixed 86_400_000: a daylight-saving day is 23 or 25 hours long, and
  // subtracting a day of milliseconds lands inside the wrong day on both of those.
  final DateTime at = DateTime.fromMillisecondsSinceEpoch(today);
  // Day 0 normalises to the previous month's last, so the first of a month needs no special case.
  final int start = DateTime(
    at.year,
    at.month,
    at.day - 1,
  ).millisecondsSinceEpoch;
  return dayStartMillis == start ? 'YESTERDAY' : '';
}

/// A day header's absolute half, as the design cases it.
String useSmileIDSampleAbsoluteDay(int dayStartMillis) {
  final DateTime at = DateTime.fromMillisecondsSinceEpoch(dayStartMillis);
  final String day = at.day.toString().padLeft(2, '0');
  return '${_weekdays[at.weekday - 1]}, $day ${_months[at.month - 1]} ${at.year}';
}

/// A job's time, as a row shows it.
String useSmileIDSampleTimeLabel(int millis) {
  final DateTime at = DateTime.fromMillisecondsSinceEpoch(millis);
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(at.hour)}:${two(at.minute)}:${two(at.second)}';
}

/// The first eight characters, elided, which is how every id in this app is shown.
String _elide(String value) =>
    value.length > 8 ? '${value.substring(0, 8)}…' : value;

/// Upper-cased because the header is, and written out because `intl` is not in this app's graph.
const List<String> _weekdays = <String>[
  'MON',
  'TUE',
  'WED',
  'THU',
  'FRI',
  'SAT',
  'SUN',
];

/// As above, and in the design's own three-letter form.
const List<String> _months = <String>[
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];
