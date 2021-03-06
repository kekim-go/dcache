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
  int days = int.tryParse(Global.defaultDays);
  int timer = int.tryParse(Global.defaultTimer);
  String rootRecursive = Global.defaultRootRecursive;
  String printAll = Global.defaultPrintAll;

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
        print('purge: purged=$purged, consumed=$consumed <- root=$root, count=$count, expire=$days, printAll=$printAll');
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
            final List<FileSystemEntity> files = Directory(found).listSync(
              recursive: recursive,
              followLinks: followLinks,
            );
            const bool purgeReally = true;
            final bool purgeDays = days > 0 ? true : false;
            final bool purgeCount = files.length > count;
            final bool purgeHere = purgeDays || purgeCount;
            if (printAllFiles) {
              print('> path=$found: files=${files.length}');
              for (int i=0; i<files.length; i++) {
                final String file = files[i].path;
                print('file[$i]=$file');
              }
            }
            if (purgeHere) {
              print('> purge here: path=$found, files=${files.length}, count=$count, days=$days');
              files.sort((a, b) {
                final int l = (a as File).lastModifiedSync().millisecondsSinceEpoch;
                final int r = (b as File).lastModifiedSync().millisecondsSinceEpoch;
                return r.compareTo(l);
              });
              int purged = 0;
              if (purgeDays) {
                final DateTime today = DateTime.now();
                for (int i=files.length-1; i>=0; i--) {
                  final String file = files[i].path;
                  final DateTime datetime = lastModified(file);
                  final Duration difference = today.difference(datetime);
                  final bool expired = difference.inDays >= days;
                  if (expired) {
                    print('>>> deleted: days=${difference.inDays}, file=$file, datetime=$datetime');
                    if (purgeReally) delete(file);
                    purged++;
                  }
                  else break;
                }
              }
              if (purgeCount) {
                final int length = files.length - purged;
                for (int i=count; i<length; i++) {
                  final String file = files[i].path;
                  final DateTime datetime = lastModified(file);
                  print('>>> deleted: index=$i, file=$file, datetime=$datetime');
                  if (purgeReally) delete(file);
                }
              }
            }
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
