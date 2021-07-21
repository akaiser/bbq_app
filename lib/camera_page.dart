import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;

import 'package:bbq_app/shared/prefs.dart';
import 'package:bbq_app/shared/state.dart';
import 'package:bbq_app/shared/ui/preferred_size.dart';
import 'package:bbq_app/shared/util/environment.dart';
import 'package:bbq_app/webview_page.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

class CameraPage extends StatefulWidget {
  CameraPage(this.cameras, {Key? key})
      : cameraMenuItems = cameras.map(
          (camera) => DropdownMenuItem<CameraDescription>(
            value: camera,
            child: Text(describeEnum(camera.lensDirection)),
          ),
        ),
        resolutionMenuItems = ResolutionPreset.values.map(
          (res) => DropdownMenuItem<ResolutionPreset>(
            value: res,
            child: Text(describeEnum(res)),
          ),
        ),
        super(key: key);

  final List<CameraDescription> cameras;
  final Iterable<DropdownMenuItem<CameraDescription>> cameraMenuItems;
  final Iterable<DropdownMenuItem<ResolutionPreset>> resolutionMenuItems;

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late Timer _timer;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  late CameraDescription _selectedCamera;
  var _selectedResolution = ResolutionPreset.medium;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(preferredOrientations);
    _selectedCamera = widget.cameras.first;
    _timer = Timer.periodic(processInterval, (_) => _process());
    _setupCamera();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _setupCamera() {
    _controller = CameraController(
      _selectedCamera,
      _selectedResolution,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    )
      ..setFlashMode(FlashMode.off)
      ..setFocusMode(FocusMode.auto);

    _initializeControllerFuture = _controller.initialize();
  }

  Future<void> _process() async {
    final state = context.read<AppState>();

    try {
      if (state.isRunning && !state.isProcessing) {
        state.setProcessing(true);

        await _initializeControllerFuture
            .then((_) => _controller.takePicture())
            .then((f) => _uploadFile(f, MediaQuery.of(context).orientation))
            .then((_) => state.setProcessing(false));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );

      state.stopTheWorld();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSizeWidgetWrapper(
        child: Opacity(
          opacity: 0.6,
          child: AppBar(
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.only(top: progressBarHeight),
              child: Row(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 20),
                      const Text('Cam:', style: mainTextStyle),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<CameraDescription>(
                          value: _selectedCamera,
                          items: [...widget.cameraMenuItems],
                          onChanged: (camera) {
                            if (_selectedCamera != camera) {
                              _selectedCamera = camera!;
                              setState(_setupCamera);
                            }
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      const Text('Res:', style: mainTextStyle),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<ResolutionPreset>(
                          value: _selectedResolution,
                          items: [...widget.resolutionMenuItems],
                          onChanged: (resolution) {
                            if (_selectedResolution != resolution) {
                              _selectedResolution = resolution!;
                              setState(_setupCamera);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.web),
                onPressed: () => Navigator.pushNamed(
                  context,
                  WebViewPage.route,
                ),
              )
            ],
            bottom: const _ProgressIndicator(),
          ),
        ),
      ),
      floatingActionButton: const _ActionButton(),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: Text('Loading...'));
          } else {
            // https://medium.com/lightsnap/making-a-full-screen-camera-application-in-flutter-65db7f5d717b
            return SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.aspectRatio,
                  child: CameraPreview(_controller),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _uploadFile(
    XFile file,
    Orientation orientation,
  ) async {
    final response = await post(
      Uri.parse(Environment.uploadUrl),
      body: {
        'image': base64Encode(await file.readAsBytes()),
        'device': Environment.deviceDescription,
        'orientation': orientation.toString().split('.').last,
      },
    );
    log('Server returned: ${response.statusCode}');
  }
}

class _ProgressIndicator extends StatelessWidget
    implements PreferredSizeWidget {
  const _ProgressIndicator({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(progressBarHeight);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: progressBarHeight,
      child: Selector<AppState, bool>(
        selector: (_, state) => state.isProcessing,
        builder: (_, isProcessing, __) => isProcessing
            ? const LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                backgroundColor: Colors.transparent,
              )
            : const SizedBox(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (_, state, __) {
        final isRunning = state.isRunning;
        return FloatingActionButton.extended(
          onPressed: () => state.setRunning(!isRunning),
          backgroundColor: isRunning ? Colors.red : Colors.black,
          label: Text(
            isRunning ? 'Stop' : 'Record',
            style: const TextStyle(color: Colors.white),
          ),
          icon: Icon(
            isRunning ? Icons.stop : Icons.fiber_manual_record,
            color: Colors.white,
          ),
        );
      },
    );
  }
}
