// The script will
// 1. Copy `docs/wireframe.md` to `docs/.wireframe.md`.
// 2. In `docs/.wireframe.md`, replace all `*.excalidraw` paths (excluding `*.excalidraw.svg`)
//    to use the `.svg` extension.
// 3. Export `*.excalidraw` files to svg `*.svg` by
//    `npx --no-install excalidraw-to-svg {file_path}.excalidraw`.

import 'dart:io';

void main(List<String> args) async {
  final cwd = Directory.current;
  final docsDir = Directory('${cwd.path}/docs');
  final sourceMd = File('${docsDir.path}/wireframe.md');
  final targetMd = File('${docsDir.path}/.wireframe.md');

  if (!await docsDir.exists()) {
    stderr.writeln('docs directory not found at: ${docsDir.path}');
    exitCode = 1;
    return;
  }
  if (!await sourceMd.exists()) {
    stderr.writeln('Source markdown not found: ${sourceMd.path}');
    exitCode = 1;
    return;
  }

  // 1) Copy wireframe.md to .wireframe.md (overwrite to keep it up-to-date)
  stdout.writeln('Copying ${sourceMd.path} -> ${targetMd.path}');
  await targetMd.writeAsBytes(await sourceMd.readAsBytes(), flush: true);

  // 2) Replace *.excalidraw (not already followed by .svg) with *.svg in the copied markdown
  final content = await targetMd.readAsString();
  final replaced = content.replaceAll(RegExp(r"\.excalidraw(?!\.svg)"), '.svg');
  if (replaced != content) {
    stdout.writeln('Updating links in ${targetMd.path} to use .svg');
    await targetMd.writeAsString(replaced);
  } else {
    stdout.writeln('No link updates needed in ${targetMd.path}');
  }

  // 3) Find all *.excalidraw files under docs and export to *.svg using excalidraw-to-svg
  stdout.writeln('Scanning for .excalidraw assets under ${docsDir.path}');
  final excalidrawFiles = <File>[];
  await for (final entity in docsDir.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File && entity.path.endsWith('.excalidraw')) {
      excalidrawFiles.add(entity);
    }
  }

  if (excalidrawFiles.isEmpty) {
    stdout.writeln('No .excalidraw files found. Done.');
    return;
  }

  // Verify npx availability; if missing, skip export with a clear message.
  bool hasNpx = false;
  try {
    final npxCheck = await Process.run(
      'npx',
      ['--version'],
      runInShell: true,
      workingDirectory: cwd.path,
    );
    hasNpx = npxCheck.exitCode == 0;
  } catch (_) {
    hasNpx = false;
  }
  if (!hasNpx) {
    stderr.writeln(
      'npx not found. Skipping SVG export. Install Node.js (npx) and ensure excalidraw-to-svg is available locally.',
    );
    return;
  }

  int exported = 0;
  for (final src in excalidrawFiles) {
    final destPath = src.path.replaceFirst(RegExp(r'\.excalidraw$'), '.svg');
    final dest = File(destPath);

    // Skip if up-to-date
    if (await dest.exists()) {
      try {
        final srcStat = await src.stat();
        final destStat = await dest.stat();
        if (!srcStat.modified.isAfter(destStat.modified)) {
          stdout.writeln('Skip (up-to-date): ${dest.path}');
          continue;
        }
      } catch (_) {
        // If stats fail, proceed to export
      }
    }

    stdout.writeln('Exporting to SVG via excalidraw-to-svg: ${src.path}');
    final result = await Process.run(
      'npx',
      ['--no-install', 'excalidraw-to-svg', src.path],
      runInShell: true,
      workingDirectory: cwd.path,
    );
    if (result.exitCode == 0) {
      stdout.writeln('Exported: ${dest.path}');
      exported++;
    } else {
      stderr.writeln(
        'Failed to export ${src.path} -> ${dest.path}\n${result.stderr}\n${result.stdout}',
      );
    }
  }

  stdout.writeln('Completed. ${exported} file(s) exported.');
}
