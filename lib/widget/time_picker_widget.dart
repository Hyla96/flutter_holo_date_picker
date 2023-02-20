import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../date_picker_constants.dart';
import '../date_picker_theme.dart';
import '../date_time_formatter.dart';
import '../i18n/date_picker_i18n.dart';

/// DatePicker widget.
class TimePickerWidget extends StatefulWidget {
  TimePickerWidget({
    Key? key,
    this.firstTime,
    this.lastTime,
    this.initialTime,
    this.dateFormat = DATETIME_PICKER_DATE_FORMAT,
    this.locale = DATETIME_PICKER_LOCALE_DEFAULT,
    this.pickerTheme = DateTimePickerTheme.Default,
    this.onCancel,
    this.onChange,
    this.onConfirm,
    this.looping = false,
  }) : super(key: key) {
    // TODO: Improve here
    // assert(minTime..compareTo(maxTime) < 0);
  }

  final TimeOfDay? firstTime, lastTime, initialTime;
  final String? dateFormat;
  final DateTimePickerLocale? locale;
  final DateTimePickerTheme? pickerTheme;

  final TimeVoidCallback? onCancel;
  final TimeValueCallback? onChange, onConfirm;
  final bool looping;

  @override
  State<StatefulWidget> createState() => _TimePickerWidgetState(this.firstTime, this.lastTime, this.initialTime);
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  late TimeOfDay _minDateTime, _maxDateTime;
  int? _currHour, _currMinute;
  List<int>? _hourRange, _minuteRange;
  FixedExtentScrollController? _hourScrollCtrl, _minuteScrollCtrl;

  late Map<String, FixedExtentScrollController?> _scrollCtrlMap;
  late Map<String, List<int>?> _valueRangeMap;

  bool _isChangeDateRange = false;
  // whene change year the returned month is incorrect with the shown one
  // So _lock make sure that month doesn't change from cupertino widget
  // we will handle it manually
  bool _lock = false;

  _TimePickerWidgetState(
    TimeOfDay? minTime,
    TimeOfDay? maxTime,
    TimeOfDay? initialTime,
  ) {
    // handle current selected year、month、day
    TimeOfDay _initDateTime = initialTime ?? TimeOfDay.fromDateTime(DateTime.now());
    this._currHour = _initDateTime.hour;
    this._currMinute = _initDateTime.minute;

    // handle DateTime range
    this._minDateTime = minTime ?? TimeOfDay.fromDateTime(DateTime.parse(TIME_PICKER_MIN_TIME));
    this._maxDateTime = maxTime ?? TimeOfDay.fromDateTime(DateTime.parse(TIME_PICKER_MAX_TIME));

    // limit the range of year
    this._hourRange = _calcHourRange();
    this._currHour = min(max(_minDateTime.hour, _currHour!), _maxDateTime.hour);

    // limit the range of month
    this._minuteRange = _calcMinuteRange();
    this._currMinute = _calcCurrentMonth();

    // create scroll controller
    _hourScrollCtrl = FixedExtentScrollController(initialItem: _currHour! - _hourRange!.first);
    _minuteScrollCtrl = FixedExtentScrollController(initialItem: _currMinute! - _minuteRange!.first);

    _scrollCtrlMap = {
      'H': _hourScrollCtrl,
      'm': _minuteScrollCtrl,
    };
    _valueRangeMap = {
      'H': _hourRange,
      'm': _minuteRange,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      //padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
      child: GestureDetector(
        child: Material(color: Colors.transparent, child: _renderPickerView(context)),
      ),
    );
  }

  /// render date picker widgets
  Widget _renderPickerView(BuildContext context) {
    Widget timePickerWidget = _renderTimePickerWidget();

    return timePickerWidget;
  }

  /// notify selected date changed
  void _onSelectedChange() {
    if (widget.onChange != null) {
      TimeOfDay time = TimeOfDay(
        hour: _currHour!,
        minute: _currMinute!,
      );
      widget.onChange!(time, _calcSelectIndexList());
    }
  }

  /// find scroll controller by specified format
  FixedExtentScrollController? _findScrollCtrl(String format) {
    FixedExtentScrollController? scrollCtrl;
    _scrollCtrlMap.forEach((key, value) {
      if (format.contains(key)) {
        scrollCtrl = value;
      }
    });
    return scrollCtrl;
  }

  /// find item value range by specified format
  List<int>? _findPickerItemRange(String format) {
    List<int>? valueRange;
    _valueRangeMap.forEach((key, value) {
      if (format.contains(key)) {
        valueRange = value;
      }
    });
    return valueRange;
  }

  /// render the picker widget of year、month and day
  Widget _renderTimePickerWidget() {
    List<Widget> pickers = [];

    List<int> valueRangeHour = _findPickerItemRange('H')!;

    final hourColumn = _renderDatePickerColumnComponent(
        scrollCtrl: _findScrollCtrl('H'),
        valueRange: valueRangeHour,
        format: 'HH',
        valueChanged: (value) {
          _lock = true;
          _changeHourSelection(value);
          _lock = false;
        },
        fontSize: widget.pickerTheme!.itemTextStyle.fontSize ?? sizeByFormat(widget.dateFormat!));
    pickers.add(hourColumn);

    List<int> valueRangeMinute = _findPickerItemRange('m')!;

    final minuteColumn = _renderDatePickerColumnComponent(
        scrollCtrl: _findScrollCtrl('m'),
        valueRange: valueRangeMinute,
        format: 'mm',
        valueChanged: (value) {
          if (_lock) {
            _lock = false;
            return;
          }
          _changeMinuteSelection(value);
        },
        fontSize: widget.pickerTheme!.itemTextStyle.fontSize ?? sizeByFormat(widget.dateFormat!));
    pickers.add(minuteColumn);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: pickers),
    );
  }

  Widget _dividerWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.pickerTheme!.dividerSpacing ?? MediaQuery.of(context).size.width * 0.02,
      ),
      child: Divider(
        color: widget.pickerTheme!.dividerColor ?? widget.pickerTheme!.itemTextStyle.color,
        height: widget.pickerTheme!.dividerHeight ?? DATETIME_PICKER_DIVIDER_HEIGHT,
        thickness: widget.pickerTheme!.dividerThickness ?? DATETIME_PICKER_DIVIDER_THICKNESS,
      ),
    );
  }

  Widget _renderDatePickerColumnComponent(
      {required FixedExtentScrollController? scrollCtrl,
      required List<int> valueRange,
      required String format,
      required ValueChanged<int> valueChanged,
      double? fontSize}) {
    return Expanded(
      flex: 1,
      child: Stack(
        fit: StackFit.loose,
        children: <Widget>[
          Positioned(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 18),
              height: widget.pickerTheme!.pickerHeight,
              decoration: BoxDecoration(color: widget.pickerTheme!.backgroundColor),
              child: CupertinoPicker(
                selectionOverlay: Container(),
                backgroundColor: widget.pickerTheme!.backgroundColor,
                scrollController: scrollCtrl,
                squeeze: widget.pickerTheme?.squeeze ?? DATETIME_PICKER_SQUEEZE,
                diameterRatio: widget.pickerTheme?.diameterRatio ?? DATETIME_PICKER_DIAMETER_RATIO,
                itemExtent: widget.pickerTheme!.itemHeight,
                onSelectedItemChanged: valueChanged,
                looping: widget.looping,
                children: List<Widget>.generate(
                  valueRange.last - valueRange.first + 1,
                  (index) {
                    return _renderDatePickerItemComponent(
                      valueRange.first + index,
                      format,
                      fontSize,
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            child: Container(
              margin: EdgeInsets.only(
                top: (widget.pickerTheme!.pickerHeight / 2) - (widget.pickerTheme!.itemHeight / 2),
              ),
              child: _dividerWidget(),
            ),
          ),
          Positioned(
            child: Container(
              margin: EdgeInsets.only(
                top: (widget.pickerTheme!.pickerHeight / 2) + (widget.pickerTheme!.itemHeight / 2),
              ),
              child: _dividerWidget(),
            ),
          ),
        ],
      ),
    );
  }

  double sizeByFormat(String format) {
    if (format.contains("-MMMM") || format.contains("MMMM-")) return DATETIME_PICKER_ITEM_TEXT_SIZE_SMALL;

    return DATETIME_PICKER_ITEM_TEXT_SIZE_BIG;
  }

  Widget _renderDatePickerItemComponent(int value, String format, double? fontSize) {
    var weekday = DateTime(_currHour!, _currMinute!, value).weekday;

    return Container(
      height: widget.pickerTheme!.itemHeight,
      alignment: Alignment.center,
      child: AutoSizeText(
        DateTimeFormatter.formatDateTime(value, format, widget.locale, weekday),
        maxLines: 1,
        // style: TextStyle(
        //     color: widget.pickerTheme!.itemTextStyle.color,
        //     fontSize: fontSize ?? widget.pickerTheme!.itemTextStyle.fontSize
        // ),

        style: widget.pickerTheme?.itemTextStyle ?? DATETIME_PICKER_ITEM_TEXT_STYLE,
      ),
    );
  }

  /// change the selection of year picker
  void _changeHourSelection(int index) {
    int hour = _hourRange!.first + index;
    if (_currHour != hour) {
      _currHour = hour;
      _changeDateRange();
      _onSelectedChange();
    }
  }

  /// change the selection of month picker
  void _changeMinuteSelection(int index) {
    _minuteRange = _calcMinuteRange();

    int month = _minuteRange!.first + index;
    if (_currMinute != month) {
      _currMinute = month;

      _changeDateRange();
      _onSelectedChange();
    }
  }

  // get the correct month
  int? _calcCurrentMonth() {
    int? _currMonth = this._currMinute!;
    List<int> monthRange = _calcMinuteRange();
    if (_currMonth < monthRange.last) {
      _currMonth = max(_currMonth, monthRange.first);
    } else {
      _currMonth = max(monthRange.last, monthRange.first);
    }

    return _currMonth;
  }

  /// change range of month and day
  void _changeDateRange() {
    if (_isChangeDateRange) {
      return;
    }
    _isChangeDateRange = true;

    List<int> minuteRange = _calcMinuteRange();
    bool minuteRangeChanged = _minuteRange!.first != minuteRange.first || _minuteRange!.last != minuteRange.last;
    if (minuteRangeChanged) {
      // selected year changed
      _currMinute = _calcCurrentMonth();
    }

    setState(() {
      _minuteRange = minuteRange;
      _valueRangeMap['m'] = minuteRange;
    });

    if (minuteRangeChanged) {
      // CupertinoPicker refresh data not working (https://github.com/flutter/flutter/issues/22999)
      int currMonth = _currMinute!;
      _minuteScrollCtrl!.jumpToItem(minuteRange.last - minuteRange.first);
      if (currMonth < minuteRange.last) {
        _minuteScrollCtrl!.jumpToItem(currMonth - minuteRange.first);
      }
    }

    _isChangeDateRange = false;
  }

  /// whether or not is leap year
  bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
  }

  /// calculate selected index list
  List<int> _calcSelectIndexList() {
    int yearIndex = _currHour! - _minDateTime.hour;
    int monthIndex = _currMinute! - _minuteRange!.first;
    return [
      yearIndex,
      monthIndex,
    ];
  }

  /// calculate the range of year
  List<int> _calcHourRange() {
    return [_minDateTime.hour, _maxDateTime.hour];
  }

  /// calculate the range of month
  List<int> _calcMinuteRange() {
    int minMinute = 0, maxMinute = 59;
    int minHour = _minDateTime.hour;
    int maxHour = _maxDateTime.hour;
    if (minHour == _currHour) {
      // selected minimum year, limit month range
      minMinute = _minDateTime.minute;
    }
    if (maxHour == _currHour) {
      // selected maximum year, limit month range
      maxMinute = _maxDateTime.minute;
    }
    return [minMinute, maxMinute];
  }
}
