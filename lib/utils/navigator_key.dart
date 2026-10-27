import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool _isDialogShowing = false;

void showNoInternetDialog() {
  final context = navigatorKey.currentContext;
  if (context == null || _isDialogShowing) return;

  _isDialogShowing = true;
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.red),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No Internet Connection',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: const Text(
        'Please check your network settings and try again.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            _isDialogShowing = false;
            Navigator.of(ctx, rootNavigator: true).pop();
          },
          child: const Text(
            'OK',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  ).then((_) => _isDialogShowing = false);
}
