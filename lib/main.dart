import 'package:core/core.dart' as core;
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: MyHomePage()));
  core.start();
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BIP 157/158 SPV Wallet')
      )
    );
  }
}