import 'package:bbq_app/shared/util/device.dart';
import 'package:bbq_app/shared/util/system.dart';

class Environment {
  Environment._();

  static const _prodEnv = 'https://bbq-be.herokuapp.com';
  static const _devEnv = 'http://10.0.2.2/own/bbq_be';

  static late String deviceDescription;
  static late String baseUrl;
  static late String uploadUrl;

  static Future<void> init() async {
    final isDesktopOrWeb = System.isDesktop || System.isWeb;
    final device = isDesktopOrWeb ? DesktopDevice() : MobileDevice();
    deviceDescription = '${await device.manufacturer} - ${await device.model}';
    baseUrl = await device.isPhysicalDevice ? _prodEnv : _devEnv;
    uploadUrl = '$baseUrl/upload.php';
  }
}
