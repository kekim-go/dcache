/// dcache designed by ilshookim
/// MIT License
/// 
/// https://github.com/ilshookim/dcache
/// 
/// working directory:
/// /app                <- working directory
/// /app/dcache         <- program directory
/// /app/dcache/monitor <- monitor directory (default)
/// /app/dcache/mounted <- monitor directory (mounted)
/// 
import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:args/args.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:stack_trace/stack_trace.dart';

import 'global.dart';
import 'api.dart';

void main(List<String> arguments) async {
  final String function = Trace.current().frames[0].member;
  try {
    final ArgParser argParser = ArgParser()
      ..addOption(Global.portOption, abbr: Global.portAbbrOption)
      ..addOption(Global.rootOption, abbr: Global.rootAbbrOption)
      ..addOption(Global.countOption, abbr: Global.countAbbrOption)
      ..addOption(Global.periodOption, abbr: Global.periodAbbrOption)
      ..addOption(Global.printAllOption, abbr: Global.printAllAbbrOption);
    final ArgResults argResults = argParser.parse(arguments);
    final String portOption = argResults[Global.portOption] ?? Platform.environment[Global.portEnvOption] ?? Global.defaultPort;
    final String countOption = argResults[Global.countOption] ?? Platform.environment[Global.countEnvOption] ?? Global.defaultCount;
    final String periodOption = argResults[Global.periodOption] ?? Platform.environment[Global.periodEnvOption] ?? Global.defaultPeriod;
    final String printAllOption = argResults[Global.printAllOption] ?? Platform.environment[Global.printAllEnvOption] ?? Global.defaultPrintAll;
    final String rootOption = argResults[Global.rootOption] ?? Platform.environment[Global.rootEnvOption] ?? Global.defaultRoot;
    final bool rootExists = Directory(rootOption).existsSync();
    final String rootMounted = rootExists ? rootOption : Global.defaultRoot;

    final String host = Global.defaultHost;
    final int port = int.tryParse(portOption);
    final Handler handler = API().v1(root: rootMounted, count: int.tryParse(countOption), period: int.tryParse(periodOption), printAll: printAllOption);
    final HttpServer server = await serve(handler, host, port);

    final Map pubspec = await Global.pubspec();
    final String name = pubspec[Global.name];
    final String version = pubspec[Global.version];
    final String description = pubspec[Global.description];
    print('$name $version - $description serving at http://${server.address.host}:${server.port}');
    print('purge monitor to $rootMounted using options: root=$rootOption, count=$countOption, period=$periodOption, printAll=$printAllOption');
  }
  catch (exc) {
    print('$function: $exc');
  }
}
