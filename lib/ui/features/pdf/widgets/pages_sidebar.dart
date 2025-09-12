import 'package:flutter/material.dart';
import 'thumbnails_view.dart';

class PagesSidebar extends StatelessWidget {
  const PagesSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(margin: EdgeInsets.zero, child: const ThumbnailsView());
  }
}
