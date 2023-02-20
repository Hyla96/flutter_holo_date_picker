import 'package:flutter/material.dart';

/// Selected value of DatePicker.
typedef DateValueCallback(DateTime dateTime, List<int> selectedIndex);

/// Pressed cancel callback.
typedef DateVoidCallback();

/// Default value of minimum datetime.
const String DATE_PICKER_MIN_DATETIME = "1900-01-01 00:00:00";

/// Default value of maximum datetime.
const String DATE_PICKER_MAX_DATETIME = "2100-12-31 23:59:59";

/// Default value of date format
const String DATETIME_PICKER_DATE_FORMAT = 'yyyy-MMM-dd';

/// Default value of time format
const String DATETIME_PICKER_TIME_FORMAT = 'HH:mm:ss';

/// Default value of datetime format
const String DATETIME_PICKER_DATETIME_FORMAT = 'yyyyMMdd HH:mm:ss';

/// Selected value of DatePicker.
typedef TimeValueCallback(TimeOfDay dateTime, List<int> selectedIndex);

/// Pressed cancel callback.
typedef TimeVoidCallback();

const String TIME_PICKER_MAX_TIME = "2100-12-31 23:59:59";

const String TIME_PICKER_MIN_TIME = "1900-01-01 00:00:00";
