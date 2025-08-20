import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/node_editor_screen.dart';
import 'models/canvas_model.dart';

void main() {
  runApp(const NodeEditorApp());
}

class NodeEditorApp extends StatelessWidget {
  const NodeEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CanvasModel(),
      child: MaterialApp(
        title: 'Node Editor',
        theme: ThemeData.dark(),
        home: const NodeEditorScreen(),
      ),
    );
  }
}
