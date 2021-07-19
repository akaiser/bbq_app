import 'package:bbq_app/shared/util/device.dart';
import 'package:bbq_app/shared/util/system.dart';

class Environment {
  Environment._();

  static const _prodEnv = 'http://www.sgs-automobile.de';
  static const _devEnv = 'http://10.0.2.2/own/sgs-automobile';

  static late String _baseUrl;
  static late String _deviceDescription;

  static Future<void> init() async {
    final isDesktopOrWeb = System.isDesktop || System.isWeb;
    final device = isDesktopOrWeb ? DesktopDevice() : MobileDevice();
    _baseUrl = await device.isPhysicalDevice ? _prodEnv : _devEnv;
    _deviceDescription = '${await device.manufacturer} - ${await device.model}';
  }

  static String get deviceDescription => _deviceDescription;

  static String get webUrl => '$_baseUrl/bbq';

  static String get uploadUrl => '$webUrl/upload.php';
}
