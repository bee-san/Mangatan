import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

// A 2x2, two-frame GIF. The first frame is red and the second is blue.
final Uint8List _animatedGif = base64Decode(
  'R0lGODlhAgACAIEAAP8AAAAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQACgAAACwAAA'
  'AAAgACAAAIBgABCAQQEAAh+QQACgAAACwAAAAAAgACAIEAAP8AAAAAAAAAAAAIBgABCAQQEAA7',
);

Future<List<int>> _firstPixel(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List().take(4).toList();
}

void main() {
  test('desktop reader codec preserves animated GIF frames', () async {
    // Mangatan's CustomExtendedNetworkImageProvider, MemoryImage, and FileImage
    // all pass encoded bytes through the host Flutter engine's image codec.
    // Assert that the desktop codec keeps the animation rather than flattening
    // the GIF to its first frame.
    final codec = await ui.instantiateImageCodec(_animatedGif);
    addTearDown(codec.dispose);

    expect(codec.frameCount, 2);
    expect(codec.repetitionCount, -1); // GIF loop count 0 means repeat forever.

    final first = await codec.getNextFrame();
    final second = await codec.getNextFrame();
    addTearDown(first.image.dispose);
    addTearDown(second.image.dispose);

    expect(first.duration, const Duration(milliseconds: 100));
    expect(second.duration, const Duration(milliseconds: 100));
    expect(await _firstPixel(first.image), <int>[255, 0, 0, 255]);
    expect(await _firstPixel(second.image), <int>[0, 0, 255, 255]);
  });
}
