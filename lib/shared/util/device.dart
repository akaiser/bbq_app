import 'package:bbq_app/shared/util/system.dart';
import 'package:device_info_plus/device_info_plus.dart';

abstract class _Device {
  _Device() : _deviceInfoPlugin = DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfoPlugin;

  Future<bool> get isPhysicalDevice;

  Future<String> get manufacturer;

  Future<String> get model;
}

class MobileDevice extends _Device {
  @override
  Future<bool> get isPhysicalDevice {
    if (System.isAndroid) {
      return _deviceInfoPlugin.androidInfo
          .then((info) => info.isPhysicalDevice)
          .then((isPhysicalDevice) => isPhysicalDevice ?? false);
    }

    return _deviceInfoPlugin.iosInfo.then((info) => info.isPhysicalDevice);
  }

  @override
  Future<String> get manufacturer {
    if (System.isAndroid) {
      return _deviceInfoPlugin.androidInfo
          .then((info) => info.manufacturer)
          .then((manufacturer) => manufacturer ?? 'NA');
    }
    return _deviceInfoPlugin.iosInfo
        .then((info) => info.identifierForVendor)
        .then((identifierForVendor) => identifierForVendor ?? 'NA');
  }

  @override
  Future<String> get model {
    if (System.isAndroid) {
      return _deviceInfoPlugin.androidInfo
          .then((info) => info.model)
          .then((model) => model ?? 'NA');
    }

    return _deviceInfoPlugin.iosInfo
        .then((info) => info.utsname.machine)
        .then((model) => model ?? 'NA');
  }
}

class DesktopDevice extends _Device {
  @override
  Future<bool> get isPhysicalDevice async => false;

  @override
  Future<String> get manufacturer async {
    if (System.isLinux) {
      return 'Some Linux machine';
    } else if (System.isMacOS) {
      return 'Some Mac machine';
    }
    return 'Some Windows machine';
  }

  @override
  Future<String> get model async {
    if (System.isLinux) {
      return _deviceInfoPlugin.linuxInfo.then((info) => info.prettyName);
    } else if (System.isMacOS) {
      return _deviceInfoPlugin.macOsInfo.then((info) => info.model);
    }
    return _deviceInfoPlugin.windowsInfo.then((info) => info.computerName);
  }
}
