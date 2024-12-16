import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

base class Coordinate extends Struct {
  @Double()
  external double x;

  @Double()
  external double y;

  static Pointer<Coordinate> allocate(double x, double y) {
    final pointer = malloc<Coordinate>();
    pointer.ref
      ..x = x
      ..y = y;
    return pointer;
  }
}

base class NativeDetectionResult extends Struct {
  external Pointer<Coordinate> topLeft;
  external Pointer<Coordinate> topRight;
  external Pointer<Coordinate> bottomLeft;
  external Pointer<Coordinate> bottomRight;

  static Pointer<NativeDetectionResult> allocate(
      Pointer<Coordinate> topLeft,
      Pointer<Coordinate> topRight,
      Pointer<Coordinate> bottomLeft,
      Pointer<Coordinate> bottomRight) {
    final pointer = malloc<NativeDetectionResult>();
    pointer.ref
      ..topLeft = topLeft
      ..topRight = topRight
      ..bottomLeft = bottomLeft
      ..bottomRight = bottomRight;
    return pointer;
  }
}

class EdgeDetectionResult {
  EdgeDetectionResult({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  Offset topLeft;
  Offset topRight;
  Offset bottomLeft;
  Offset bottomRight;
}

typedef DetectEdgesFunction = Pointer<NativeDetectionResult> Function(
    Pointer<Utf8> imagePath,
    );

typedef ProcessImageFunctionNative = Int8 Function(
    Pointer<Utf8> imagePath,
    Double topLeftX,
    Double topLeftY,
    Double topRightX,
    Double topRightY,
    Double bottomLeftX,
    Double bottomLeftY,
    Double bottomRightX,
    Double bottomRightY,
    );

typedef ProcessImageFunction = int Function(
    Pointer<Utf8> imagePath,
    double topLeftX,
    double topLeftY,
    double topRightX,
    double topRightY,
    double bottomLeftX,
    double bottomLeftY,
    double bottomRightX,
    double bottomRightY,
    );

class EdgeDetection {
  static Future<EdgeDetectionResult> detectEdges(String path) async {
    final nativeEdgeDetection = _getDynamicLibrary();

    final detectEdges = nativeEdgeDetection
        .lookup<NativeFunction<DetectEdgesFunction>>("detect_edges")
        .asFunction<DetectEdgesFunction>();

    final detectionResult = detectEdges(path.toNativeUtf8(allocator: malloc)).ref;

    return EdgeDetectionResult(
      topLeft: Offset(
        detectionResult.topLeft.ref.x,
        detectionResult.topLeft.ref.y,
      ),
      topRight: Offset(
        detectionResult.topRight.ref.x,
        detectionResult.topRight.ref.y,
      ),
      bottomLeft: Offset(
        detectionResult.bottomLeft.ref.x,
        detectionResult.bottomLeft.ref.y,
      ),
      bottomRight: Offset(
        detectionResult.bottomRight.ref.x,
        detectionResult.bottomRight.ref.y,
      ),
    );
  }

  static Future<bool> processImage(String path, EdgeDetectionResult result) async {
    final nativeEdgeDetection = _getDynamicLibrary();

    final processImage = nativeEdgeDetection
        .lookup<NativeFunction<ProcessImageFunctionNative>>("process_image")
        .asFunction<ProcessImageFunction>();

    final resultCode = processImage(
      path.toNativeUtf8(allocator: malloc),
      result.topLeft.dx,
      result.topLeft.dy,
      result.topRight.dx,
      result.topRight.dy,
      result.bottomLeft.dx,
      result.bottomLeft.dy,
      result.bottomRight.dx,
      result.bottomRight.dy,
    );

    return resultCode == 1;
  }

  static DynamicLibrary _getDynamicLibrary() {
    return Platform.isAndroid
        ? DynamicLibrary.open("libnative_edge_detection.so")
        : DynamicLibrary.process();
  }
}
