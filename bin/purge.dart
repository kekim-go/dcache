/// dcache designed by ilshookim
/// MIT License
/// 
/// https://github.com/ilshookim/dcache
/// 
import 'dart:async';
import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:dcli/src/functions/is.dart';

import 'global.dart';

class Purge {
  String root = Global.defaultRoot;
  int count = int.tryParse(Global.defaultCount);

  Stopwatch _consume = Stopwatch();
  Duration _duration = Duration(seconds: 1);
  Timer _timer;

  Purge({Duration duration, bool autostart = false}) {
    try {
      _duration = duration ?? _duration;
    }
    catch (exc) {
      print('constructor: $exc');
    }
    finally {
      if (autostart) start();
    }
  }

  bool get isActive => _timer != null && _timer.isActive;
  bool get isRunning => _consume.isRunning;

  bool start() {
    bool succeed = false;
    try {
      if (isRunning)
        return succeed;
      if (root == null || !Directory(root).existsSync())
        return succeed;
      if (!isActive) {
        _timer = Timer.periodic(_duration, _periodic);
        succeed = true;
      }
    }
    catch (exc) {
      print('start: $exc');
    }
    return succeed;
  }

  bool stop() {
    bool succeed = false;
    try {
      if (isActive) {
        _timer.cancel();
        succeed = true;
      }
    }
    catch (exc) {
      print('stop: $exc');
    }
    return succeed;
  }

  void _periodic(Timer timer) async {
    if (_consume.isRunning)
      return;
      int purged = 0;
    try {
      _consume.start();
      purged = await _purge(root);
      _consume.stop();
    }
    catch (exc) {
      print('periodic: $exc');
    }
    finally {
      final int consumed = _consume.elapsedMilliseconds;
      print('purge: purged=$purged, consumed=$consumed <- root=$root, count=$count');
      _consume.reset();
    }
  }

  Future<int> _purge(String root) async {
    int purged = 0;
    try {
      final String pattern = '*';
      find(pattern, 
        root: root, 
        recursive: true, 
        types: [Find.directory], 
        progress: Progress((String found) {
          bool succeed = false;
          try {
            if (!_timer.isActive)
              return succeed;
            final List<String> files = find(pattern, root: found, recursive: false).toList();
            final bool printAllFilesInPurgeHere = true;
            final int  printFilesUntil = 10;
            final bool purgeTruly = false;
            final bool printPurgeFiles = true;
            final bool purgeHere = files.length > count;
            if (purgeHere) {
              print('> too many files in a path: path=$found, files=${files.length}, count=$count');
              files.sort((a, b) {
                final DateTime l = lastModified(a);
                final DateTime r = lastModified(b);
                return l.compareTo(r);
              });
              if (printAllFilesInPurgeHere) {
                int howManyFilesArePrinted = files.length;
                final bool untilSpecified = printFilesUntil > 0;
                if (untilSpecified) howManyFilesArePrinted = printFilesUntil;
                for (int i=0; i<howManyFilesArePrinted; i++) {
                  final String file = files[i];
                  final DateTime datetime = lastModified(file);
                  print('  > index=$i: file=$file, datetime=$datetime');
                }
                if (untilSpecified) print('  > print skipped: until=$howManyFilesArePrinted');
              }
              for (int i=count; i<files.length; i++) {
                final String file = files[i];
                final DateTime datetime = lastModified(file);
                if (printPurgeFiles) print('>>> deleted: index=$i, file=$file, datetime=$datetime');
                if (purgeTruly) delete(file);
              }
            }
            succeed = true;
          }
          catch (exc) {
            print('path: $exc');
          }
          return succeed;
      }));
    }
    catch (exc) {
      print('purge: $exc');
    }
    return purged;
  }
}
