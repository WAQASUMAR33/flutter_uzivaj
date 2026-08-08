import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool _isDialogShowing = false;

void showNoInternetDialog() {
  final context = navigatorKey.currentContext;
  if (context == null || _isDialogShowing) return;

  _isDialogShowing = true;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.red),
          SizedBox(width: 10),
          Text('No Internet Connection'),
        ],
      ),
      content: const Text(
        'Please check your network settings and try again.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            _isDialogShowing = false;
            // Closes the application
            SystemNavigator.pop();
            // Fallback
            exit(0);
          },
          child: const Text(
            'OK',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
