import 'dart:isolate';
import 'dart:ui';

class IsolateManager {
  static const FOREGROUND_PORT_NAME = "foreground_port";

  static SendPort? lookupPortByName() {
    return IsolateNameServer.lookupPortByName(FOREGROUND_PORT_NAME);
  }

  static bool registerPortWithName(SendPort port) {
    removePortNameMapping(FOREGROUND_PORT_NAME);
    return IsolateNameServer.registerPortWithName(port, FOREGROUND_PORT_NAME);
  }

  static bool removePortNameMapping(String name) {
    return IsolateNameServer.removePortNameMapping(name);
  }
}
