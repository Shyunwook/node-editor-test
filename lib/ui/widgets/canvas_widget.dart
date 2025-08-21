import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/canvas_model.dart';
import '../../models/node_model.dart';
import 'node_widget.dart';
import 'connection_painter.dart';

class CanvasWidget extends StatefulWidget {
  const CanvasWidget({super.key});

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  Widget build(BuildContext context) {
    return Consumer<CanvasModel>(
      builder: (context, canvasModel, child) {
        return SizedBox.expand(
          child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.1,
            maxScale: 5.0,
            constrained: false,
            scaleEnabled: true,
            panEnabled: true,
            child: MouseRegion(
              onHover: (event) {
                if (canvasModel.isConnecting) {
                  // InteractiveViewer 내부에서는 로컬 좌표 직접 사용
                  canvasModel.updateTemporaryConnection(event.localPosition);
                }
              },
              child: GestureDetector(
                onTapDown: (details) => _handleTapDown(details, canvasModel),
                child: DragTarget<NodeType>(
                  onAcceptWithDetails: (details) =>
                      _handleNodeDrop(details, canvasModel),
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      width: 50000, // 매우 큰 고정 캔버스 크기
                      height: 50000,
                      color: candidateData.isNotEmpty
                          ? Colors.grey[800]
                          : Colors.grey[900],
                      child: CustomPaint(
                        painter: GridPainter(canvasModel),
                        child: Stack(
                          children: [
                            // 연결선을 노드들 뒤에 그리기
                            CustomPaint(
                              painter: ConnectionPainter(canvasModel),
                              size: const Size(50000, 50000),
                            ),
                            // 노드들을 렌더링
                            ...canvasModel.nodes.map(
                              (node) => AnimatedBuilder(
                                animation: node,
                                builder: (context, child) {
                                  return Positioned(
                                    left: node.position.dx,
                                    top: node.position.dy,
                                    child: NodeWidget(
                                      node: node,
                                      onPositionChanged: (newPosition) {
                                        node.position = newPosition;
                                      },
                                      onTap: () {
                                        canvasModel.setSelectedNode(node);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTapDown(TapDownDetails details, CanvasModel canvasModel) {
    // 연결 중인 경우 취소
    if (canvasModel.isConnecting) {
      canvasModel.cancelConnection();
      return;
    }

    // 빈 공간 클릭 시 노드 선택 해제
    canvasModel.setSelectedNode(null);
  }

  void _handleNodeDrop(
    DragTargetDetails<NodeType> details,
    CanvasModel canvasModel,
  ) {
    // DragTarget이 InteractiveViewer 내부에 있으므로 좌표 변환 필요
    final transform = _transformationController.value;
    final canvasPosition = MatrixUtils.transformPoint(
      Matrix4.inverted(transform),
      details.offset,
    );
    final nodeType = details.data;
    
    // 디버그 로그
    print('🔴 [NODE_DROP] Raw Offset: ${details.offset}');
    print('🔴 [NODE_DROP] Canvas Position: $canvasPosition');

    // 새 노드 생성
    final newNode = NodeModel(
      id: 'node_${DateTime.now().millisecondsSinceEpoch}',
      type: nodeType,
      title: _getNodeTitle(nodeType),
      position: canvasPosition,
    );

    // 노드 타입에 따라 포트 추가
    _addPortsForNodeType(newNode, nodeType);

    canvasModel.addNode(newNode);
  }

  String _getNodeTitle(NodeType type) {
    switch (type) {
      case NodeType.scene:
        return 'Video Scene';
      case NodeType.actor:
        return 'Video Actor';
      case NodeType.detector:
        return 'Detector';
      case NodeType.combine:
        return 'Combine';
      case NodeType.action:
        return 'Action';
    }
  }

  void _addPortsForNodeType(NodeModel node, NodeType type) {
    switch (type) {
      case NodeType.scene:
        node.addOutputPort('scene_out', 'Scene', color: Colors.blue);
        break;
      case NodeType.actor:
        node.addInputPort('scene_in', 'Scene', color: Colors.blue);
        node.addInputPort('trigger_in', 'Trigger', color: Colors.orange);
        node.addOutputPort('action_out', 'Action', color: Colors.red);
        break;
      case NodeType.detector:
        node.addOutputPort('signal_out', 'Signal', color: Colors.orange);
        break;
      case NodeType.combine:
        node.addInputPort('input1', 'Input 1', color: Colors.purple);
        node.addInputPort('input2', 'Input 2', color: Colors.purple);
        node.addOutputPort('output', 'Output', color: Colors.purple);
        break;
      case NodeType.action:
        node.addInputPort('trigger_in', 'Trigger', color: Colors.red);
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    // 초기화는 한 번만 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final canvasModel = context.read<CanvasModel>();
      if (canvasModel.nodes.isEmpty) {
        _initializeTestNodes(canvasModel);
      }

      // 초기 뷰를 노드들이 있는 위치로 이동 (25000, 25000 근처)
      // 화면 중앙이 캔버스의 25000, 25000 위치가 되도록 변환
      final screenSize = MediaQuery.of(context).size;
      final translation = Matrix4.identity()
        ..translate(
          screenSize.width / 2 - 25150.0, // 노드 위치 - 화면 중앙
          screenSize.height / 2 - 25150.0,
        );
      _transformationController.value = translation;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _initializeTestNodes(CanvasModel canvasModel) {
    // 테스트용 노드 추가 - 캔버스 중앙에 배치
    final sceneNode = NodeModel(
      id: 'test1',
      type: NodeType.scene,
      title: 'Video Scene',
      position: const Offset(25000, 25000), // 캔버스 중앙
    );
    sceneNode.addOutputPort('scene_out', 'Scene Output', color: Colors.blue);
    canvasModel.addNode(sceneNode);

    final actorNode = NodeModel(
      id: 'test2',
      type: NodeType.actor,
      title: 'Video Actor',
      position: const Offset(25300, 25200), // 캔버스 중앙 근처
    );
    actorNode.addInputPort('scene_in', 'Scene Input', color: Colors.blue);
    actorNode.addInputPort('trigger_in', 'Trigger', color: Colors.orange);
    actorNode.addOutputPort('action_out', 'Action', color: Colors.red);
    canvasModel.addNode(actorNode);
  }
}

class GridPainter extends CustomPainter {
  final CanvasModel canvasModel;

  GridPainter(this.canvasModel);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 1.0;

    const gridSize = 20.0;

    // 수직선 그리기
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 수평선 그리기
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
