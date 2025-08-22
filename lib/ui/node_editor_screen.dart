import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/widgets/canvas_widget.dart';
import '../ui/widgets/node_palette.dart';
import '../ui/widgets/properties_panel.dart';
import '../models/canvas_model.dart';

class NodeEditorScreen extends StatefulWidget {
  const NodeEditorScreen({super.key});

  @override
  State<NodeEditorScreen> createState() => _NodeEditorScreenState();
}

class _NodeEditorScreenState extends State<NodeEditorScreen>
    with TickerProviderStateMixin {
  late AnimationController _propertiesAnimationController;
  late Animation<double> _propertiesSlideAnimation;

  @override
  void initState() {
    super.initState();
    _propertiesAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _propertiesSlideAnimation = Tween<double>(begin: 1, end: 0.0).animate(
      CurvedAnimation(
        parent: _propertiesAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _propertiesAnimationController.dispose();
    super.dispose();
  }

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
      body: Consumer<CanvasModel>(
        builder: (context, canvasModel, child) {
          // 노드 선택 상태에 따라 애니메이션 제어
          if (canvasModel.selectedNode != null) {
            _propertiesAnimationController.forward();
          } else {
            _propertiesAnimationController.reverse();
          }

          return Stack(
            children: [
              // 메인 콘텐츠
              Row(
                children: [
                  // 노드 팔레트 (왼쪽)
                  const SizedBox(width: 250, child: NodePalette()),
                  // 캔버스 (중앙)
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: () {
                        // 배경 탭 시 노드 선택 해제
                        canvasModel.setSelectedNode(null);
                      },
                      child: const CanvasWidget(),
                    ),
                  ),
                ],
              ),
              // 슬라이딩 Properties 패널
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _propertiesSlideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(300 * _propertiesSlideAnimation.value, 0),
                      child: Container(
                        width: 300,
                        color: Colors.grey[850],
                        child: const PropertiesPanel(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
