import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/splash.mp4')
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
        });
        // Remove the native splash screen ONLY when the video is ready to prevent flickering
        FlutterNativeSplash.remove();
        
        // Start playing the video
        _controller.setVolume(0.0); // Muted by default for a non-intrusive splash
        _controller.play();

        // Listen for completion
        _controller.addListener(_checkVideoProgress);
      }).catchError((e) {
        // Fallback if video fails to load
        FlutterNativeSplash.remove();
        if (mounted) {
          context.go('/dashboard'); // GoRouter redirect logic will handle unauthenticated users
        }
      });
  }

  void _checkVideoProgress() {
    if (_controller.value.isInitialized && 
        _controller.value.position >= _controller.value.duration) {
      _controller.removeListener(_checkVideoProgress);
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkVideoProgress);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Assumes a white background matches the MP4 edges
      body: Center(
        child: _initialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
