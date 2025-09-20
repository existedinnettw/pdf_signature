import 'package:pdf_signature/domain/models/model.dart';

class SignatureDragData {
  final SignatureCard card; // null means use current processed signature
  const SignatureDragData({required this.card});
}
