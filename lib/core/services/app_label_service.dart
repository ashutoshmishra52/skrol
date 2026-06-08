import 'package:flutter/services.dart';
import '../constants/app_packages.dart';

class AppLabelService {
  static const _channel = MethodChannel('com.ashutoshmishra.scrollless/platform');
  static final Map<String, String> _cache = {};

  static Future<String> getLabel(String packageName) async {
    if (_cache.containsKey(packageName)) return _cache[packageName]!;

    final fallback = AppPackages.displayName(packageName);
    try {
      final label = await _channel.invokeMethod<String>(
        'getAppLabel',
        {'packageName': packageName},
      );
      if (label != null && label.isNotEmpty) {
        _cache[packageName] = label;
        return label;
      }
    } catch (_) {}

    _cache[packageName] = fallback;
    return fallback;
  }

  static Future<Map<String, String>> getLabels(List<String> packages) async {
    final result = <String, String>{};
    final missing = <String>[];

    for (final pkg in packages) {
      if (_cache.containsKey(pkg)) {
        result[pkg] = _cache[pkg]!;
      } else {
        missing.add(pkg);
      }
    }

    if (missing.isNotEmpty) {
      try {
        final labels = await _channel.invokeMethod<Map<Object?, Object?>>(
          'getAppLabels',
          {'packages': missing},
        );
        if (labels != null) {
          for (final entry in labels.entries) {
            final pkg = entry.key.toString();
            final name = entry.value?.toString() ?? AppPackages.displayName(pkg);
            _cache[pkg] = name;
            result[pkg] = name;
          }
        }
      } catch (_) {
        for (final pkg in missing) {
          result[pkg] = AppPackages.displayName(pkg);
        }
      }
    }

    return result;
  }
}
