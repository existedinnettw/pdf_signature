import 'package:pdf_signature/data/model/model.dart';

class SignatureDragData {
  final SignatureAsset? asset; // null means use current processed signature
  const SignatureDragData({this.asset});
}
