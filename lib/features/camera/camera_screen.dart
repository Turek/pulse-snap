import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

/// Closed hierarchy of camera-screen states. Using a sealed class instead of
/// loose nullable fields means the build method's switch is exhaustive and
/// no two states (e.g. "denied" + "ready") can coexist by accident.
sealed class _CameraState {
  const _CameraState();
}

class _Initializing extends _CameraState {
  const _Initializing();
}

class _Denied extends _CameraState {
  final String message;
  // True when the permission is permanently denied or restricted —
  // requesting again is a no-op, so the user has to flip the switch in
  // iOS Settings. We render an "Open Settings" recovery UI in that case.
  final bool blocked;
  const _Denied({required this.message, required this.blocked});
}

class _NoCameras extends _CameraState {
  const _NoCameras();
}

class _Ready extends _CameraState {
  final CameraController controller;
  const _Ready(this.controller);
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  _CameraState _state = const _Initializing();
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the user toggles the permission in Settings and returns to the app,
    // re-run setup so the preview comes up without forcing them to back out
    // of the screen and re-enter it.
    if (state == AppLifecycleState.resumed && _state is _Denied) {
      _retry();
    }
  }

  void _retry() {
    setState(() => _state = const _Initializing());
    _setup();
  }

  Future<void> _setup() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      final blocked = status.isPermanentlyDenied || status.isRestricted;
      setState(() => _state = _Denied(
            blocked: blocked,
            message: blocked
                ? 'PulseSnap needs camera access to capture readings. Enable it in Settings.'
                : 'Camera permission is required to capture a reading.',
          ));
      return;
    }
    final cameras = await availableCameras();
    if (!mounted) return;
    if (cameras.isEmpty) {
      setState(() => _state = const _NoCameras());
      return;
    }
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _state = _Ready(controller));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final s = _state;
    if (s is _Ready) {
      // Ensure torch is off before the controller is torn down, otherwise
      // the LED can be left on after navigating away.
      s.controller.setFlashMode(FlashMode.off).catchError((_) {});
      s.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleFlash(CameraController controller) async {
    final next = !_flashOn;
    await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
    if (mounted) setState(() => _flashOn = next);
  }

  Future<void> _capture(CameraController controller) async {
    if (!controller.value.isInitialized) return;
    try {
      final picture = await controller.takePicture();
      // Torch stays on continuously until explicitly cleared.
      if (_flashOn) {
        await controller.setFlashMode(FlashMode.off);
        if (mounted) setState(() => _flashOn = false);
      }
      if (!mounted) return;
      context.pushNamed('review', extra: File(picture.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture failed: $e')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    context.pushNamed('review', extra: File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: switch (_state) {
        _Initializing() => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        _Denied(:final message, :final blocked) => _PermissionErrorView(
            message: message,
            blocked: blocked,
            onRetry: _retry,
          ),
        _NoCameras() => const Center(
            child: Text(
              'No cameras available',
              style: TextStyle(color: Colors.white),
            ),
          ),
        _Ready(:final controller) => _CameraPreviewLayer(
            controller: controller,
            flashOn: _flashOn,
            onToggleFlash: () => _toggleFlash(controller),
            onCapture: () => _capture(controller),
            onPickFromGallery: _pickFromGallery,
          ),
      },
    );
  }
}

class _CameraPreviewLayer extends StatelessWidget {
  const _CameraPreviewLayer({
    required this.controller,
    required this.flashOn,
    required this.onToggleFlash,
    required this.onCapture,
    required this.onPickFromGallery,
  });

  final CameraController controller;
  final bool flashOn;
  final VoidCallback onToggleFlash;
  final VoidCallback onCapture;
  final VoidCallback onPickFromGallery;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        const _GuideOverlay(),
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      flashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                    onPressed: onToggleFlash,
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library,
                        color: Colors.white),
                    onPressed: onPickFromGallery,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FloatingActionButton.large(
                heroTag: 'capture',
                onPressed: onCapture,
                child: const Icon(Icons.camera_alt, size: 40),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionErrorView extends StatelessWidget {
  const _PermissionErrorView({
    required this.message,
    required this.blocked,
    required this.onRetry,
  });

  final String message;
  final bool blocked;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_outlined,
              color: Colors.white70, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 24),
          if (blocked)
            FilledButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              onPressed: openAppSettings,
            )
          else
            FilledButton(
              onPressed: onRetry,
              child: const Text('Grant camera access'),
            ),
          TextButton(
            onPressed: () => context.go('/'),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _GuideOverlay extends StatelessWidget {
  const _GuideOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 280,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white70, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Position your device here',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
