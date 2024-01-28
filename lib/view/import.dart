import 'package:flutter/material.dart';
import 'package:kagyo_kanri/view/import_list.dart';

import 'autoimport.dart';

class Import extends StatefulWidget {
  const Import({Key? key}) : super(key: key);

  @override
  _ImportState createState() => _ImportState();   
}

class _ImportState extends State<Import> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("インポート"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            // （2） 実際に表示するページ(ウィジェット)を指定する
                            builder: (context) => ImportList()));
                  },
                  child: Text("手動で入力する")),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AutoImport(),
                      ),
                    );
                  },
                  child: Text("自動読み込み"))
              // Add your import-related widgets here
            ],
          ),
        ),
      ),
    );
  }
}
