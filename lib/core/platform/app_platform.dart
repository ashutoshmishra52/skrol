import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

bool get isAndroidPlatform => !kIsWeb && Platform.isAndroid;

bool get isIOSPlatform => !kIsWeb && Platform.isIOS;

bool get supportsUsageStats => isAndroidPlatform;

bool get supportsReelsTracking => isAndroidPlatform;
