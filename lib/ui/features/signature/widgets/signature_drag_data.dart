import 'package:pdf_signature/domain/models/model.dart';

class SignatureDragData {
  final SignatureAsset? asset; // null means use current processed signature
  const SignatureDragData({this.asset});
}
