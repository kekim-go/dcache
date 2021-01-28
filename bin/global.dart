/// dcache designed by ilshookim
/// MIT License
/// 
/// https://github.com/ilshookim/dcache
/// 
import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';
import 'package:stack_trace/stack_trace.dart';

extension BoolParsing on String {
  bool parseBool() {
    final String lowerCase = this.toLowerCase();
    if (lowerCase.isEmpty || lowerCase == 'false') return false;
    return lowerCase == 'true' || lowerCase != '0';
  }
}

class Global {
  static final String defaultHost = '0.0.0.0';
  static final String defaultPort = '8088';
  static final String defaultRoot = './dcache/cache';
  static final String defaultCount = '5000';
  static final String defaultTimer = '1';
  static final String defaultRootRecursive = 'true';
  static final String defaultPrintAll = 'false';
  static final String portOption = 'port';
  static final String portAbbrOption = 'p';
  static final String portEnvOption = 'DCACHE_PORT';
  static final String rootOption = 'root';
  static final String rootAbbrOption = 'r';
  static final String rootEnvOption = 'DCACHE_ROOT';
  static final String countOption = 'count';
  static final String countAbbrOption = 'c';
  static final String countEnvOption = 'DCACHE_COUNT';
  static final String timerOption = 'timer';
  static final String timerAbbrOption = 'e';
  static final String timerEnvOption = 'DCACHE_TIMER';
  static final String rootRecursiveOption = 'recursive';
  static final String rootRecursiveAbbrOption = 'u';
  static final String rootRecursiveEnvOption = 'DCACHE_ROOT_RECURSIVE';
  static final String printAllOption = 'print';
  static final String printAllAbbrOption = 't';
  static final String printAllEnvOption = 'DCACHE_PRINT_ALL';

  static final String indexName = 'index.html';
  static final String faviconName = 'favicon.ico';
  static final String dcachePath = '../dcache';
  static final int exitCodeCommandLineUsageError = 64;

  static final String currentPath = dirname(Platform.script.toFilePath());
  static final String yamlName = 'pubspec.yaml';
  static final String name = 'name';
  static final String version = 'version';
  static final String description = 'description';
  
  static Future<Map> pubspec() async {
    final String function = Trace.current().frames[0].member;
    Map yaml = Map();
    try {
      final String path = join(Global.currentPath, '../$yamlName');
      final File file = new File(path);
      final String text = await file.readAsString();
      yaml = loadYaml(text);
    }
    catch (exc) {
      print('$function: $exc');
    }
    return yaml;
  }
}
