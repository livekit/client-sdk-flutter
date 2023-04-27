import 'key_provider.dart';

enum EncryptionType {
  kNone,
  kGcm,
  kCustom,
}

class E2EEOptions {
  final BaseKeyProvider keyProvider;
  final EncryptionType encryptionType = EncryptionType.kGcm;
  const E2EEOptions({required this.keyProvider});
}
