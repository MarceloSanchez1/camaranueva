import 'package:camerawesome/models/exif_preferences_data.dart';
import 'package:camerawesome/models/media_capture.dart';
import 'package:camerawesome/src/widgets/base_view/bottom_widget.dart';
import 'package:camerawesome/src/widgets/base_view/mid_widget.dart';
import 'package:camerawesome/src/widgets/base_view/top_widget.dart';
import 'package:camerawesome/src/widgets/camera_controls_widget.dart';
import 'package:flutter/material.dart';

import '../controllers/camera_setup.dart';
import '../../controllers/sensor_config.dart';
import '../../models/capture_modes.dart';
import '../../models/flashmodes.dart';
import '../../models/sensors.dart';
import '../orchestrator/camera_orchestrator.dart';
import '../widgets/camera_preview.dart';
import '../widgets/pinch_to_zoom.dart';

typedef LineBuilder = Widget Function(CameraSetup, SensorConfig);

typedef FilePathBuilder = Future<String> Function(CaptureModes)?;

class CameraWidgetBuilder extends StatefulWidget {
  // Initial camera config
  final CaptureModes captureMode;
  final Sensors sensor;
  final CameraFlashes flashMode;
  final double zoom;
  final List<CaptureModes> availableModes;
  final ExifPreferences? exifPreferences;
  final bool enableAudio;
  final Future<String> Function(CaptureModes)? picturePathBuilder;
  final Future<String> Function(CaptureModes)? videoPathBuilder;
  final Function(MediaCapture)? onMediaTap;
  final CameraOrchestrator cameraOrchestrator;

  // Widgets
  final Widget? progressIndicator;
  final LineBuilder builder;

  CameraWidgetBuilder._({
    required this.captureMode,
    required this.sensor,
    required this.flashMode,
    required this.zoom,
    required this.availableModes,
    required this.exifPreferences,
    required this.enableAudio,
    required this.progressIndicator,
    required this.builder,
    required this.picturePathBuilder,
    required this.videoPathBuilder,
    required this.onMediaTap,
    required this.cameraOrchestrator,
  });

  factory CameraWidgetBuilder.awesome({
    CaptureModes captureMode = CaptureModes.PHOTO,
    Sensors sensor = Sensors.BACK,
    CameraFlashes flashMode = CameraFlashes.NONE,
    double zoom = 0.0,
    List<CaptureModes> availableModes = const [
      CaptureModes.PHOTO,
      CaptureModes.VIDEO
    ],
    ExifPreferences? exifPreferences,
    bool enableAudio = true,
    Widget? progressIndicator,
    LineBuilder? top,
    LineBuilder? middle,
    LineBuilder? bottom,
    Future<String> Function(CaptureModes)? picturePathBuilder,
    Future<String> Function(CaptureModes)? videoPathBuilder,
    final Function(MediaCapture)? onMediaTap,
  }) {
    /// TODO refactor this (those two args could be merged)
    if (availableModes.contains(CaptureModes.PHOTO) &&
        picturePathBuilder == null) {
      throw ("You have to provide a path through [picturePathBuilder] to save your picture");
    }

    /// TODO refactor this (those two args could be merged)
    if (availableModes.contains(CaptureModes.VIDEO) &&
        videoPathBuilder == null) {
      throw ("You have to provide a path through [videoPathBuilder] to save your picture");
    }
    return CameraWidgetBuilder._(
      captureMode: captureMode,
      sensor: sensor,
      flashMode: flashMode,
      zoom: zoom,
      availableModes: availableModes,
      exifPreferences: exifPreferences,
      enableAudio: enableAudio,
      progressIndicator: progressIndicator,
      builder: ((cameraSetup, sensorConfig) => CameraControlsWidget(
            cameraSetup: cameraSetup,
            sensorConfig: sensorConfig,
            top: top ??
                (setup, sensorConfig) => TopWidget(sensorConfig: sensorConfig),
            middle: middle ??
                (setup, sensorConfig) => MidWidget(
                      sensorConfig: sensorConfig,
                      cameraSetup: cameraSetup,
                    ),
            bottom: bottom ??
                (setup, sensorConfig) => BottomWidget(
                      cameraSetup: cameraSetup,
                      sensorConfig: sensorConfig,
                      onMediaTap: onMediaTap,
                    ),
          )),
      picturePathBuilder: picturePathBuilder,
      videoPathBuilder: videoPathBuilder,
      onMediaTap: onMediaTap,
      cameraOrchestrator: CameraOrchestrator.create(
        SensorConfig(
          sensor: sensor,
          flash: flashMode,
          currentZoom: zoom,
        ),
      ),
    );
  }

  CameraWidgetBuilder.custom(
      {CaptureModes captureMode = CaptureModes.PHOTO,
      Sensors sensor = Sensors.BACK,
      CameraFlashes flashMode = CameraFlashes.NONE,
      double zoom = 0.0,
      List<CaptureModes> availableModes = const [
        CaptureModes.PHOTO,
        CaptureModes.VIDEO
      ],
      ExifPreferences? exifPreferences,
      bool enableAudio = true,
      Widget? progressIndicator,
      required LineBuilder builder,
      Future<String> Function(CaptureModes)? picturePathBuilder,
      Future<String> Function(CaptureModes)? videoPathBuilder,
      Function(MediaCapture)? onMediaTap})
      : this._(
          captureMode: captureMode,
          sensor: sensor,
          flashMode: flashMode,
          zoom: zoom,
          availableModes: availableModes,
          exifPreferences: exifPreferences,
          enableAudio: enableAudio,
          progressIndicator: progressIndicator,
          builder: builder,
          picturePathBuilder: picturePathBuilder,
          videoPathBuilder: videoPathBuilder,
          onMediaTap: onMediaTap,
          cameraOrchestrator: CameraOrchestrator.create(
            SensorConfig(
              sensor: sensor,
              flash: flashMode,
              currentZoom: zoom,
            ),
          ),
        );

  @override
  State<StatefulWidget> createState() {
    return _CameraWidgetBuilder();
  }
}

class _CameraWidgetBuilder extends State<CameraWidgetBuilder>
    with WidgetsBindingObserver {
  // CameraSetup? _cameraSetup;
  // SensorConfig? _sensorConfig;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.cameraOrchestrator.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CameraWidgetBuilder oldWidget) {
    // use freezed + copy with
    // cameraOrchestrator.state.setFlash(widget.flashMode);
    // cameraOrchestrator.state.setZoom(widget.zoom);
    if (widget.captureMode != oldWidget.captureMode &&
        widget.captureMode == CaptureModes.PHOTO) {
      widget.cameraOrchestrator.startPictureMode(widget.picturePathBuilder);
    } else if (widget.captureMode != oldWidget.captureMode &&
        widget.captureMode == CaptureModes.VIDEO) {
      widget.cameraOrchestrator.startVideoMode(widget.videoPathBuilder);
    }
    super.didUpdateWidget(oldWidget);
  }

  // @override
  // void didUpdateWidget(covariant CameraWidgetBuilder oldWidget) {
  //   // Check for differences between previous config and this one and update _cameraSetup and sensorConfig accordingly
  //   if (widget.flashMode != oldWidget.flashMode) {
  //     _sensorConfig?.setFlashMode(widget.flashMode);
  //   }
  //   if (widget.zoom != oldWidget.zoom) {
  //     _sensorConfig?.setZoom(widget.zoom);
  //   }
  //   if (widget.captureMode != oldWidget.captureMode) {
  //     if (widget.availableModes.contains(widget.captureMode)) {
  //       // Check if we already have picture / video controller, if not add them
  //       _cameraSetup?.setCaptureMode(
  //         widget.captureMode,
  //         pictureCameraControllerBuilder:
  //             _cameraSetup?.pictureCameraController == null &&
  //                     widget.captureMode == CaptureModes.PHOTO
  //                 ? (setup) => PictureCameraController.create(
  //                       cameraSetup: setup,
  //                       picturePathBuilder: widget.picturePathBuilder,
  //                       exifPreferences: widget.exifPreferences,
  //                     )
  //                 : null,
  //         videoCameraControllerBuilder:
  //             _cameraSetup?.videoCameraController == null &&
  //                     widget.captureMode == CaptureModes.VIDEO
  //                 ? (setup) => VideoCameraController.create(
  //                     cameraSetup: setup,
  //                     videoPathBuilder: widget.videoPathBuilder,
  //                     enableAudio: widget.enableAudio)
  //                 : null,
  //       );
  //     }
  //   }

  //   super.didUpdateWidget(oldWidget);
  // }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        widget.cameraOrchestrator.state.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        widget.cameraOrchestrator.state.stop();
        break;
    }
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   super.didChangeAppLifecycleState(state);
  //   switch (state) {
  //     case AppLifecycleState.resumed:
  //       _cameraSetup?.start();
  //       break;
  //     case AppLifecycleState.inactive:
  //     case AppLifecycleState.paused:
  //     case AppLifecycleState.detached:
  //       _cameraSetup?.stop();
  //       break;
  //   }
  // }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    //FIXME MOVE THIS FROM HERE
    final sensorConfig = SensorConfig(
      sensor: widget.sensor,
      currentZoom: widget.zoom,
      flash: widget.flashMode,
    );
    // TODO add initial mode args
    if (widget.availableModes.contains(CaptureModes.PHOTO)) {
      widget.cameraOrchestrator.startPictureMode(widget.picturePathBuilder);
    } else if (widget.availableModes.contains(CaptureModes.VIDEO)) {
      widget.cameraOrchestrator.startVideoMode(widget.videoPathBuilder);
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addObserver(this);
  //   final sensorConfig = SensorConfig(
  //     sensor: widget.sensor,
  //     currentZoom: widget.zoom,
  //     flash: widget.flashMode,
  //   );
  //   final Future<CameraSetup> future;
  //   if (widget.availableModes.contains(CaptureModes.PHOTO) &&
  //       widget.availableModes.contains(CaptureModes.VIDEO)) {
  //     future = CameraSetup.photoAndVideo(
  //       initialCaptureMode: widget.captureMode,
  //       sensorConfig: sensorConfig,
  //       pictureCameraControllerBuilder: (cameraSetup) =>
  //           PictureCameraController.create(
  //               cameraSetup: cameraSetup,
  //               picturePathBuilder: widget.picturePathBuilder),
  //       videoCameraControllerBuilder: (cameraSetup) =>
  //           VideoCameraController.create(
  //         cameraSetup: cameraSetup,
  //         videoPathBuilder: widget.videoPathBuilder,
  //       ),
  //     );
  //   } else if (widget.availableModes.contains(CaptureModes.PHOTO)) {
  //     if (widget.captureMode != CaptureModes.PHOTO) {
  //       throw "InitialCaptureMode can't be ${widget.captureMode} when only availalble modes are ${widget.availableModes}";
  //     }
  //     future = CameraSetup.picture(
  //       sensorConfig: sensorConfig,
  //       pictureCameraControllerBuilder: ((cameraSetup) =>
  //           PictureCameraController.create(
  //               cameraSetup: cameraSetup,
  //               picturePathBuilder: widget.picturePathBuilder)),
  //     );
  //   } else if (widget.availableModes.contains(CaptureModes.VIDEO)) {
  //     if (widget.captureMode != CaptureModes.VIDEO) {
  //       throw "InitialCaptureMode can't be ${widget.captureMode} when only availalble modes are ${widget.availableModes}";
  //     }
  //     future = CameraSetup.video(
  //       sensorConfig: sensorConfig,
  //       videoCameraControllerBuilder: (cameraSetup) =>
  //           VideoCameraController.create(
  //         cameraSetup: cameraSetup,
  //         videoPathBuilder: widget.videoPathBuilder,
  //       ),
  //     );
  //   } else {
  //     throw "No CaptureModes available";
  //   }

  //   future.then((value) {
  //     _cameraSetup = value;
  //     if (mounted) setState(() {});
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CameraModeState>(
      stream: widget.cameraOrchestrator.state$,
      builder: (context, snapshot) {
        print("build");
        if (!snapshot.hasData || snapshot.data!.captureMode == null) {
          return widget.progressIndicator ??
              const Center(
                child: CircularProgressIndicator(),
              );
        }
        print(" ===> ${snapshot.data!.captureMode}");
        // if (snapshot.data is PreparingCameraState) {
        //   print("start is PreparingCameraState");
        // }
        print("start ready");
        return SafeArea(
          child: Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Positioned.fill(
                  child: PinchToZoom(
                    sensorConfig: widget.cameraOrchestrator.sensorConfig,
                    child: CameraPreviewWidget(),
                  ),
                ),
                // Positioned.fill(
                //     child: widget.builder(
                //   cameraOrchestrator,
                //   sensorSnapshot.data!,
                // ),),
              ],
            ),
          ),
        );
      },
    );
  }

  //   if (_cameraSetup == null) {
  //     return widget.progressIndicator ??
  //         const Center(
  //           child: CircularProgressIndicator(),
  //         );
  //   }

  //   return StreamBuilder<SensorConfig>(
  //     stream: _cameraSetup!.sensorConfigStream,
  //     builder: (context, sensorSnapshot) {
  //       if (sensorSnapshot.hasData) {
  //         _sensorConfig = sensorSnapshot.data;
  //         return SafeArea(
  //           child: Container(
  //             color: Colors.black,
  //             child: Stack(
  //               fit: StackFit.expand,
  //               children: <Widget>[
  //                 Positioned.fill(
  //                   child: PinchToZoom(
  //                     sensorConfig: sensorSnapshot.data!,
  //                     child: CameraPreviewWidget(
  //                       cameraSetup: _cameraSetup!,
  //                     ),
  //                   ),
  //                 ),
  //                 Positioned.fill(
  //                     child: widget.builder(
  //                   _cameraSetup!,
  //                   sensorSnapshot.data!,
  //                 )),
  //               ],
  //             ),
  //           ),
  //         );
  //       } else {
  //         return widget.progressIndicator ??
  //             const Center(
  //               child: CircularProgressIndicator(),
  //             );
  //       }
  //     },
  //   );
  // }
}