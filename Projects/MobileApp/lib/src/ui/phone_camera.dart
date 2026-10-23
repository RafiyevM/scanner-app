import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

abstract interface class PhoneCamera {
  Future<void> initialize();
  Widget buildPreview();
  Future<Uint8List> takePhoto();
  Future<void> dispose();
}

typedef PhoneCameraFactory = PhoneCamera Function();

class DevicePhoneCamera implements PhoneCamera {
  CameraController? _controller;

  @override
  Future<void> initialize() async {
    final List<CameraDescription> cameras = await availableCameras();
    final CameraDescription back = cameras.firstWhere(
      (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    Object? lastError;
    for (var attempt = 0; attempt < 4; attempt++) {
      final CameraController controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      try {
        await controller.initialize();
        _controller = controller;
        return;
      } catch (error) {
        lastError = error;
        await controller.dispose();
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    throw lastError ?? StateError('Camera unavailable');
  }

  @override
  Widget buildPreview() {
    final CameraController controller = _controller!;
    final Size size = controller.value.previewSize ?? const Size(1280, 720);
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.height,
        height: size.width,
        child: CameraPreview(controller),
      ),
    );
  }

  @override
  Future<Uint8List> takePhoto() async {
    final XFile file = await _controller!.takePicture();
    try {
      return await file.readAsBytes();
    } finally {
      try {
        await File(file.path).delete();
      } catch (_) {
        // The cached photo is removed by the OS if deletion fails.
      }
    }
  }

  @override
  Future<void> dispose() async {
    final CameraController? controller = _controller;
    _controller = null;
    await controller?.dispose();
  }
}
