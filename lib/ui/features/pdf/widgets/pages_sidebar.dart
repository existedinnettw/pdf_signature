import 'package:flutter/material.dart';
import 'pdf_pages_overview.dart';

class PagesSidebar extends StatelessWidget {
  const PagesSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(margin: EdgeInsets.zero, child: const PdfPagesOverview());
  }
}
