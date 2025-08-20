import 'package:flutter/material.dart';
import '../ui/widgets/canvas_widget.dart';
import '../ui/widgets/node_palette.dart';
import '../ui/widgets/properties_panel.dart';

class NodeEditorScreen extends StatefulWidget {
  const NodeEditorScreen({super.key});

  @override
  State<NodeEditorScreen> createState() => _NodeEditorScreenState();
}

class _NodeEditorScreenState extends State<NodeEditorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Node-based Logic Editor'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // JSON 저장 기능
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () {
              // JSON 불러오기 기능
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // 노드 팔레트 (왼쪽)
          const SizedBox(
            width: 250,
            child: NodePalette(),
          ),
          // 캔버스 (중앙)
          const Expanded(
            flex: 3,
            child: CanvasWidget(),
          ),
          // 속성 패널 (오른쪽)
          Container(
            width: 300,
            color: Colors.grey[850],
            child: const PropertiesPanel(),
          ),
        ],
      ),
    );
  }
}