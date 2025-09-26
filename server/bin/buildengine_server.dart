import 'package:buildengine_server/server.dart';

void main(List<String> args) async {
  print('Starting BuildEngine Server...');
  final server = BuildEngineServer();
  await server.start();
}
