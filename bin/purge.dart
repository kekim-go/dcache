/// dcache designed by ilshookim
/// MIT License
/// 
/// https://github.com/ilshookim/dcache
/// 
import 'dart:async';
import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:dcli/src/functions/is.dart';
import 'package:stack_trace/stack_trace.dart';

import 'global.dart';

class Purge {
  String root = Global.defaultRoot;
  int count = int.tryParse(Global.defaultCount);
  int timer = int.tryParse(Global.defaultTimer);
  String rootRecursive = Global.defaultRootRecursive;
  String printAll = Global.defaultPrintAll;
  int numFiles = 0;
  Stopwatch _consume = Stopwatch();
  Timer _timer;

  Purge({bool autostart = false}) {
    if (autostart) start();
  }

  bool get isActive => _timer != null && _timer.isActive;
  bool get isRunning => _consume.isRunning;

  bool start() {
    final String function = Trace.current().frames[0].member;
    bool succeed = false;
    try {
      if (isRunning)
        return succeed;
      final bool rootExists = Directory(root).existsSync();
      if (root == null || !rootExists)
        return succeed;
      if (!isActive) {
        final Duration seconds = Duration(seconds: timer);
        _timer = Timer.periodic(seconds, _periodic);
        succeed = true;
      }
    }
    catch (exc) {
      print('$function: $exc');
    }
    return succeed;
  }

  bool stop() {
    final String function = Trace.current().frames[0].member;
    bool succeed = false;
    try {
      if (isActive) {
        _timer.cancel();
        succeed = true;
      }
    }
    catch (exc) {
      print('$function: $exc');
    }
    return succeed;
  }

  void _periodic(Timer timer) {
    if (isRunning)
      return;
    final String function = Trace.current().frames[0].member;
    int purged = 0;
    try {
      _consume.start();
      purged = _purge(root, rootRecursive.parseBool());
      _consume.stop();
    }
    catch (exc) {
      print('$function: $exc');
    }
    finally {
      final bool printAllFiles = printAll.parseBool();
      if (printAllFiles) {
        final int consumed = _consume.elapsedMilliseconds;
        print('purge: purged=$purged, consumed=$consumed <- root=$root, count=$count, printAll=$printAll');
      }
      _consume.reset();
    }
  }

  int _purge(String root, bool rootRecursive) {
    final String function = Trace.current().frames[0].member;
    int purged = 0;
    try {
      const String pattern = '*';
      final bool printAllFiles = printAll.parseBool();
      find(pattern, 
        root: root, 
        recursive: rootRecursive, 
        types: [Find.directory], 
        progress: Progress((String found) {
          bool succeed = false;
          try {
            if (!isActive)
              return succeed;
            const bool recursive = false;
            const bool followLinks = false;
            var elapsed = Map();

            Stopwatch watch = Stopwatch();
            watch.start();
            final List<FileSystemEntity> files = Directory(found).listSync(
              recursive: recursive,
              followLinks: followLinks,
            );
            numFiles = files.length;
            watch.stop();
            elapsed["FileList"] = watch.elapsedMilliseconds;
            
            watch.reset();
            watch.start();
            Map<int, List<File>> mapFiles = Map();
            for (var f in files) {
              int modified = (f as File).lastModifiedSync().millisecondsSinceEpoch;
              if (!mapFiles.containsKey(modified)) {
                mapFiles[modified] = List<File>();
              }
              mapFiles[modified].add(f as File);
            }
            var sortedKeys = mapFiles.keys.toList()..sort();
            watch.stop();
            elapsed["KeySorted"] = watch.elapsedMilliseconds;
            
            const bool purgeReally = true;
            final bool purgeHere = files.length > count;
            if (printAllFiles) {
              print('> path=$found: fileMap len=${mapFiles.length}, files=${files.length}');
              for (var key in sortedKeys) {
                print('key=$key, count=${mapFiles[key].length}');
                for (File f in mapFiles[key]) {
                  final String file = f.path;
                  print('key=$key, file=$file');
                }
              }
              for (int i=0; i<files.length; i++) {
              }
            }
            
            if (purgeHere) {
              print('> too many files in a path: path=$found, files=${numFiles}, count=$count');
              watch.reset();
              watch.start();
              for (var key in sortedKeys) {
                if (numFiles > count) {
                  for (File f in mapFiles[key]) {
                    final String file = f.path;
                    if (purgeReally && (numFiles > count)) {
                      delete(file);
                      numFiles--;
                    } else {
                      break;
                    }
                  }
                  // print('>>> deleting : key=${key}, length=${mapFiles[key].length}, numFiles=$numFiles > ${numFiles-mapFiles[key].length}');
                } else {
                  break;
                }
              }
              watch.stop();
              elapsed["FileDelete"] = watch.elapsedMilliseconds;
            }
            
            int total = 0;
            for (var key in elapsed.keys) {
              total += elapsed[key];
            }
            print('$numFiles,${elapsed["FileList"]},${elapsed["KeySorted"]},${elapsed["FileDelete"]},$total');
            succeed = true;
          }
          catch (exc) {
            print('$function: $exc');
          }
          finally {
            Future.delayed(Duration.zero);
          }
          return succeed;
        }),
      );
    }
    catch (exc) {
      print('$function: $exc');
    }
    finally {
      Future.delayed(Duration.zero);
    }
    return purged;
  }
}
