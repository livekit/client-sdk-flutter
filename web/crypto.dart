import 'dart:js_interop';
import 'dart:typed_data';

JSArrayBuffer jsArrayBufferFrom(ByteData data) {
  // Avoid copying if possible
  if (data is Uint8List &&
      data.offsetInBytes == 0 &&
      data.lengthInBytes == data.buffer.lengthInBytes) {
    return data.buffer.toJS;
  }
  // Copy
  return Uint8List.fromList(Uint8List.sublistView(data)).buffer.toJS;
}
