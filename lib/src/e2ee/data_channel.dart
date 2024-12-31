import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'key_provider.dart';

class DataChannelFrameCryptor {
  final KeyProvider keyProvider;
  final algorithm = AesGcm.with128bits();
  late SecretKey secretKey;
  late List<int> nonce;

  DataChannelFrameCryptor(
    this.keyProvider,
  );

  Future<void> init() async {
    // Generate a secret key
    secretKey = await algorithm
        .newSecretKeyFromBytes(await keyProvider.exportSharedKey());
    print('Secret key: $secretKey');

    // Generate a nonce
    nonce = algorithm.newNonce();
    print('Nonce: $nonce');
  }

  /// Encrypt
  Future<Uint8List> encrypt(Uint8List frame) async {
    final secretBox = await algorithm.encrypt(
      frame,
      secretKey: secretKey,
      nonce: nonce,
    );

    ///print('Nonce: ${secretBox.nonce}');
    ///print('Ciphertext: ${secretBox.cipherText}');
    ///print('MAC: ${secretBox.mac.bytes}');
    return Uint8List.fromList(secretBox.cipherText);
  }

  /// Decrypt
  Future<Uint8List?> decrypt(Uint8List secretBox) async {
    final clearText = await algorithm.encrypt(
      secretBox,
      secretKey: secretKey,
    );
    //print('Cleartext: $clearText');
    return Uint8List.fromList(clearText.cipherText);
  }
}
