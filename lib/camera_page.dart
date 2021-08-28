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

  final Iterable<CameraDescription> cameras;
  final Iterable<DropdownMenuItem<CameraDescription>> cameraMenuItems;
  final Iterable<DropdownMenuItem<ResolutionPreset>> resolutionMenuItems;

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late Timer _timer;
  late CameraController _controller;

  late CameraDescription _selectedCamera;
  var _selectedResolution = ResolutionPreset.medium;

  @override
  void initState() {
    super.initState();
    _selectedCamera = widget.cameras.first;
    _timer = Timer.periodic(processInterval, (_) => _process());
    _setupCamera();
  }

  @override
  void dispose() {
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
    );
  }

  Future<void> _process() async {
    final state = context.read<AppState>();

    try {
      if (state.isRunning && !state.isProcessing) {
        state.setProcessing(true);

        await _controller
            .takePicture()
            .then(_uploadFile)
            .then((_) => state.setProcessing(false));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );

      state.stopTheWorld();
    }
  }

  Future<void> _uploadFile(XFile file) async {
    final response = await post(
      Uri.parse(Environment.uploadUrl),
      body: {
        'device': Environment.deviceDescription,
        'image': base64Encode(await file.readAsBytes()),
      },
    );
    log('Server returned: ${response.statusCode}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSizeWidgetWrapper(
        child: AppBar(
          backgroundColor: const Color.fromRGBO(0, 0, 0, 0.5),
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
                        items: List.unmodifiable(widget.cameraMenuItems),
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
                        items: List.unmodifiable(widget.resolutionMenuItems),
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
              onPressed: () => Navigator.pushNamed(context, WebViewPage.route),
            )
          ],
          bottom: const _ProgressIndicator(),
        ),
      ),
      floatingActionButton: const _ActionButton(),
      body: FutureBuilder<void>(
        future: _controller
            .initialize()
            .then((_) => _controller.setFlashMode(FlashMode.off)),
        builder: (_, __) {
          if (!_controller.value.isInitialized) {
            return const Center(child: Text('Loading...'));
          } else {
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
        builder: (_, isProcessing, progressIndicator) {
          return isProcessing ? progressIndicator! : const SizedBox();
        },
        child: const LinearProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<AppState, bool>(
      selector: (_, state) => state.isRunning,
      builder: (context, isRunning, _) => FloatingActionButton.extended(
        onPressed: () => context.read<AppState>().setRunning(!isRunning),
        backgroundColor: isRunning ? Colors.red : Colors.black,
        label: Text(
          isRunning ? 'Stop' : 'Record',
          style: const TextStyle(color: Colors.white),
        ),
        icon: Icon(
          isRunning ? Icons.stop : Icons.fiber_manual_record,
          color: Colors.white,
        ),
      ),
    );
  }
}
