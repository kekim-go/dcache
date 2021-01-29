import 'dart:io';

void main(List<String> args) {
  var systemTempDir = Directory.systemTemp;
  
  Stopwatch _consume = Stopwatch();  
  var dr = systemTempDir.listSync().where((element) => (element is Directory));
  print('${_consume.elapsedMicroseconds}, ${dr.length}');

  systemTempDir.list(recursive: true, followLinks: false).listen((entity) {
      print('${entity.path}, ${_consume.elapsedMicroseconds}');
    });
      
}