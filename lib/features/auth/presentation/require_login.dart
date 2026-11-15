import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'login_screen.dart';

Future<bool> requireLogin(BuildContext context, {String? reason}) async {
  final auth = context.read<AuthProvider>();
  if (auth.isSignedIn) return true;

  final signedIn = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => LoginScreen(reason: reason),
    ),
  );
  return signedIn ?? false;
}
