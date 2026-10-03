import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: TaqatEmaarApp(),
    ),
  );
}

class TaqatEmaarApp extends StatelessWidget {
  const TaqatEmaarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taqat Emaar',
      home: Scaffold(
        body: Center(
          child: Text('Taqat Emaar'),
        ),
      ),
    );
  }
}