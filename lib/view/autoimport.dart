import 'package:flutter/material.dart';

class AutoImport extends StatefulWidget {
  const AutoImport({Key? key}) : super(key: key);

  @override
  _AutoImportState createState() => _AutoImportState();
}

class _AutoImportState extends State<AutoImport> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("自動インポート"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Add your import-related widgets here
            ],
          ),
        ),
      ),
    );
  }
}
