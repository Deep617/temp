import 'package:flutter/material.dart';

class EmptyWidget extends StatelessWidget {

  final String title;

  const EmptyWidget({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {

    return Center(
      child: Text(title),
    );
  }
}