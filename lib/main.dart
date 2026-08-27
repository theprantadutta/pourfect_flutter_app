import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureSystemChrome();

  // THE GAME IS FULLY PLAYABLE OFFLINE and no network call may ever block it.
  // Firebase only powers analytics and, later, optional cloud sync — so a
  // failure here is logged and shrugged off rather than allowed to stop a
  // player reaching level 1.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stack) {
    developer.log(
      'Firebase init failed; continuing offline',
      name: 'startup',
      error: error,
      stackTrace: stack,
    );
  }

  runApp(const ProviderScope(child: PourfectApp()));
}
