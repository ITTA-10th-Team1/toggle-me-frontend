import 'package:flutter/material.dart';

/// A new message replaces the current notice and its queue.
void showAppNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        showCloseIcon: true,
        duration: const Duration(seconds: 2),
      ),
    );
}
