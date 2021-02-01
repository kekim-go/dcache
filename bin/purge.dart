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
      final bool printAllFiles = true;//printAll.parseBool();
      if (printAllFiles) {
        final int consumed = _consume.elapsedMilliseconds;
        // print('purge: purged=$purged, consumed=$consumed <- root=$root, count=$count, printAll=$printAll');
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
            watch.stop();
            elapsed["FileList"] = watch.elapsedMilliseconds;
            
            watch.reset();
            watch.start();
            Map<int, List<File>> fileMap = Map();
            for (var f in files) {
              int modified = (f as File).lastModifiedSync().millisecondsSinceEpoch;
              if (!fileMap.containsKey(modified)) {
                fileMap[modified] = List<File>();
              }
              fileMap[modified].add(f as File);
            }
            watch.stop();
            elapsed["MakeMap"] = watch.elapsedMilliseconds;
            print('fileMap len=${fileMap.length}');
            // for (var key in fileMap.keys) {
            //   print('key=$key, count=${fileMap[key].length}');
            // }
            
            const bool purgeReally = true;
            final bool purgeHere = files.length > count;
            if (printAllFiles) {
              print('> path=$found: files=${files.length}');
              for (int i=0; i<files.length; i++) {
                final String file = files[i].path;
                print('file[$i]=$file');
              }
            }
            
            if (purgeHere) {
              // print('> too many files in a path: path=$found, files=${files.length}, count=$count');
              numFiles = files.length;

              // watch.reset();
              // watch.start();
              // files.sort((a, b) {
              //   final int l = (a as File).lastModifiedSync().millisecondsSinceEpoch;
              //   final int r = (b as File).lastModifiedSync().millisecondsSinceEpoch;
              //   return r.compareTo(l);
              // });
              // watch.stop();
              // elapsed["FileSort"] = watch.elapsedMilliseconds;

              // watch.reset();
              // watch.start();
              // for (int i=count; i<files.length; i++) {
              //   final String file = files[i].path;
              //   final DateTime datetime = lastModified(file);
              //   // print('>>> deleted: index=$i, file=$file, datetime=$datetime');
              //   if (purgeReally) delete(file);
              // }
              // watch.stop();
              // elapsed["FileDelete"] = watch.elapsedMilliseconds;

              watch.reset();
              watch.start();
              var sortedKeys = fileMap.keys.toList()..sort();
              watch.stop();
              elapsed["KeySorted"] = watch.elapsedMilliseconds;
            
              watch.reset();
              watch.start();
              int fileCounts = 0;
              for (var key in sortedKeys) {
                if ((fileCounts + fileMap[key].length) > count) {
                  // print('>>> deleting : key=${key}, length=${fileMap[key].length}, fileCounts=$fileCounts');
                  for (File f in fileMap[key]) {
                    final String file = f.path;
                    // print('>>> deleted: key=$key, file=$file');
                    if (purgeReally) delete(file);
                  }
                } else {
                  fileCounts += fileMap[key].length;
                  // print('>>> adding   : key=${key}, length=${fileMap[key].length}, fileCounts=$fileCounts');
                }
              }
              watch.stop();
              elapsed["FileDelete"] = watch.elapsedMilliseconds;

            }
            print('$numFiles,${elapsed["FileList"]},${elapsed["MakeMap"]},${elapsed["KeySorted"]},${elapsed["FileDelete"]}');//,${elapsedFileList+elapsedFileSort+elapsedFileDelete}
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
