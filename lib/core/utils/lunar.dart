/// 农历（阴历）换算 — 查表法，支持 1900-2100 年
///
/// 数据表：每年一个整数（十六进制 4 字节）：
/// - 低 4 位：闰月月份（0 = 无闰月）
/// - 第 17 位（0x10000）：闰月是否大月（30 天）
/// - 第 16..4 位：1~12 月是否大月

/// 1900-2100 年农历数据表（每年一行）
const List<int> kLunarInfo = [
  0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2, // 1900-1909
  0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977, // 1910-1919
  0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970, // 1920-1929
  0x06566, 0x0d4a0, 0x0ea50, 0x06e95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950, // 1930-1939
  0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557, // 1940-1949
  0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0, // 1950-1959
  0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0, // 1960-1969
  0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6, // 1970-1979
  0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570, // 1980-1989
  0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x055c0, 0x0ab60, 0x096d5, 0x092e0, // 1990-1999
  0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5, // 2000-2009
  0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930, // 2010-2019
  0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530, // 2020-2029
  0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45, // 2030-2039
  0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0, // 2040-2049
  0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06b20, 0x1a6c4, 0x0aae0, // 2050-2059
  0x092e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4, // 2060-2069
  0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0, // 2070-2079
  0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160, // 2080-2089
  0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a2d0, 0x0d150, 0x0f252, // 2090-2099
  0x0d520, // 2100
];

/// 农历日期
class LunarDate {
  final int year;
  final int month;
  final int day;

  /// 是否闰月
  final bool isLeap;

  const LunarDate(this.year, this.month, this.day, this.isLeap);
}

/// 农历月份名（1-12）
const List<String> kLunarMonthNames = [
  '正', '二', '三', '四', '五', '六', '七', '八', '九', '十', '冬', '腊',
];

/// 农历日名（1-30）
const List<String> kLunarDayNames = [
  '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
  '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
  '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十',
];

/// 某农历年总天数（含闰月）
int _lunarYearDays(int year) {
  final info = kLunarInfo[year - 1900];
  var days = 348;
  for (var i = 0x8000; i > 0x8; i >>= 1) {
    if ((info & i) != 0) days++;
  }
  return days + _leapDays(year);
}

/// 闰月月份（0 = 无闰月）
int _leapMonth(int year) => kLunarInfo[year - 1900] & 0xf;

/// 闰月天数（29/30；无闰月返回 0）
int _leapDays(int year) {
  if (_leapMonth(year) == 0) return 0;
  return (kLunarInfo[year - 1900] & 0x10000) != 0 ? 30 : 29;
}

/// 某农历年某月天数（29/30）
int _monthDays(int year, int month) =>
    (kLunarInfo[year - 1900] & (0x10000 >> month)) != 0 ? 30 : 29;

/// 公历 → 农历；超出 1900-01-31 ~ 2100 支持范围返回 null
LunarDate? solarToLunar(DateTime solar) {
  final base = DateTime(1900, 1, 31); // 农历 1900 年正月初一
  if (solar.isBefore(base)) return null;
  if (solar.year > 2100) return null;

  var offset = solar.difference(base).inDays;

  // 定位农历年
  var year = 1900;
  while (year < 2100) {
    final days = _lunarYearDays(year);
    if (offset < days) break;
    offset -= days;
    year++;
  }

  // 定位农历月（含闰月）
  var month = 1;
  var isLeap = false;
  final leap = _leapMonth(year);
  var daysInMonth = _monthDays(year, month);
  while (offset >= daysInMonth) {
    offset -= daysInMonth;
    if (month == leap && !isLeap) {
      // 进入闰月
      isLeap = true;
      daysInMonth = _leapDays(year);
    } else {
      month++;
      isLeap = false;
      daysInMonth = _monthDays(year, month);
    }
  }

  return LunarDate(year, month, offset + 1, isLeap);
}

/// 日历格农历显示文案：
/// - 初一 → 显示月名（如「八月」，闰月带「闰」）
/// - 其余 → 显示日名（初二…三十）
/// - 超出农历支持范围返回 null（不显示）
String? lunarDayLabel(DateTime solar) {
  final lunar = solarToLunar(solar);
  if (lunar == null) return null;
  if (lunar.day == 1) {
    final prefix = lunar.isLeap ? '闰' : '';
    return '$prefix${kLunarMonthNames[lunar.month - 1]}月';
  }
  return kLunarDayNames[lunar.day - 1];
}
