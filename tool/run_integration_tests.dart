import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Runs each integration test file sequentially to avoid multi-app start issues on desktop.
///
/// Usage:
///   dart tool/run_integration_tests.dart [--device=<id>] [--reporter=<name>] [--pattern=<glob>]
///
/// Defaults:
///   --device=linux
///   --reporter=compact
///   --pattern=*.dart (all files in integration_test/)
Future<int> main(List<String> args) async {
  // Default device depends on host OS for a better out-of-the-box experience.
  String device =
      Platform.isWindows
          ? 'windows'
          : Platform.isMacOS
          ? 'macos'
          : Platform.isLinux
          ? 'linux'
          : 'chrome';
  String reporter = 'compact';
  String pattern = '*.dart';

  for (int i = 0; i < args.length; i++) {
    final a = args[i];
    if (a.startsWith('--device=')) {
      device = a.substring(a.indexOf('=') + 1);
    } else if (a == '--device' || a == '-d') {
      if (i + 1 < args.length) {
        device = args[++i];
      }
    } else if (a.startsWith('-d=')) {
      device = a.substring(a.indexOf('=') + 1);
    } else if (a.startsWith('--reporter=')) {
      reporter = a.substring(a.indexOf('=') + 1);
    } else if (a == '--reporter' || a == '-r') {
      if (i + 1 < args.length) {
        reporter = args[++i];
      }
    } else if (a.startsWith('--pattern=')) {
      pattern = a.substring(a.indexOf('=') + 1);
    } else if (a == '--pattern') {
      if (i + 1 < args.length) {
        pattern = args[++i];
      }
    }
  }

  final dir = Directory('integration_test');
  if (!await dir.exists()) {
    stderr.writeln('integration_test/ not found. Run from the project root.');
    return 2;
  }

  final files =
      (await dir
            .list()
            .where((e) => e is File && e.path.endsWith('.dart'))
            .cast<File>()
            .toList())
        ..sort((a, b) => a.path.compareTo(b.path));

  List<File> selected;
  if (pattern == '*.dart') {
    selected = files;
  } else {
    // very simple glob: supports prefix/suffix match
    if (pattern.startsWith('*')) {
      final suffix = pattern.substring(1);
      selected = files.where((f) => f.path.endsWith(suffix)).toList();
    } else if (pattern.endsWith('*')) {
      final prefix = pattern.substring(0, pattern.length - 1);
      selected =
          files
              .where(
                (f) => f.path
                    .split(Platform.pathSeparator)
                    .last
                    .startsWith(prefix),
              )
              .toList();
    } else {
      selected = files.where((f) => f.path.contains(pattern)).toList();
    }
  }

  if (selected.isEmpty) {
    stderr.writeln('No integration tests matched pattern: $pattern');
    return 3;
  }

  // Normalize and map device aliases (helpful on Windows/macOS)
  device = _normalizedDeviceId(device);

  // Preflight: ensure `flutter` is invokable in this environment.
  final flutterOk = await _checkFlutterAvailable();
  if (!flutterOk) {
    stderr.writeln(
      'Could not execute `flutter`. Ensure Flutter is installed and on PATH.',
    );
    return 4;
  }

  stdout.writeln(
    'Running ${selected.length} integration test file(s) sequentially on device: $device...',
  );
  final results = <String, int>{};

  for (final f in selected) {
    // Convert to forward slashes for tool compatibility across platforms.
    final rel = f.path.replaceAll('\\', '/');
    stdout.writeln('\n=== Running: $rel ===');
    final args = <String>['test', rel, '-d', device, '-r', reporter];
    stdout.writeln('> flutter ${args.join(' ')}');
    final proc = await Process.start(
      'flutter',
      args,
      runInShell: Platform.isWindows, // ensures flutter.bat resolves on Windows
    );
    // Pipe output live
    unawaited(proc.stdout.transform(utf8.decoder).forEach(stdout.write));
    unawaited(proc.stderr.transform(utf8.decoder).forEach(stderr.write));
    final code = await proc.exitCode;
    results[rel] = code;
    if (code == 0) {
      stdout.writeln('=== PASSED: $rel ===');
    } else {
      stderr.writeln('=== FAILED (exit $code): $rel ===');
    }
    // Small pause between launches to let desktop/device settle (slightly longer for desktop)
    await Future<void>.delayed(
      Platform.isWindows || Platform.isMacOS || Platform.isLinux
          ? const Duration(milliseconds: 1200)
          : const Duration(milliseconds: 300),
    );
  }

  stdout.writeln('\nSummary:');
  var failures = 0;
  for (final entry in results.entries) {
    final status = entry.value == 0 ? 'PASS' : 'FAIL(${entry.value})';
    stdout.writeln(' - ${entry.key}: $status');
    if (entry.value != 0) failures += 1;
  }

  return failures == 0 ? 0 : 1;
}

String _normalizedDeviceId(String input) {
  final lower = input.toLowerCase();
  switch (lower) {
    case 'win':
    case 'windows':
    case 'windows-desktop':
      return 'windows';
    case 'mac':
    case 'macos':
    case 'darwin':
      return 'macos';
    case 'linux':
    case 'gnu/linux':
      return 'linux';
    case 'web':
    case 'chrome':
    case 'browser':
      return 'chrome';
    default:
      return input; // assume caller provided a concrete device id
  }
}

Future<bool> _checkFlutterAvailable() async {
  try {
    final result = await Process.run('flutter', const [
      '--version',
      '--suppress-analytics',
    ], runInShell: Platform.isWindows);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}
