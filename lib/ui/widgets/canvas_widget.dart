import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
  @override
  Widget build(BuildContext context) {
    return Consumer<CanvasModel>(
      builder: (context, canvasModel, child) {
        return Listener(
          onPointerSignal: (event) => _handlePointerSignal(event, canvasModel),
          child: MouseRegion(
            onHover: (event) {
              if (canvasModel.isConnecting) {
                // 로컬 좌표를 캔버스 좌표로 변환
                final canvasPosition = Offset(
                  (event.position.dx - canvasModel.offset.dx) /
                      canvasModel.scale,
                  (event.position.dy - canvasModel.offset.dy) /
                      canvasModel.scale,
                );
                canvasModel.updateTemporaryConnection(canvasPosition);
              }
            },
            child: GestureDetector(
              onPanUpdate: (details) => _handlePanUpdate(details, canvasModel),
              onTapDown: (details) => _handleTapDown(details, canvasModel),
              child: DragTarget<NodeType>(
                onAcceptWithDetails: (details) =>
                    _handleNodeDrop(details, canvasModel),
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    color: candidateData.isNotEmpty
                        ? Colors.grey[800]
                        : Colors.grey[900],
                    child: CustomPaint(
                      painter: GridPainter(canvasModel),
                      child: Transform(
                        transform: Matrix4.identity()
                          ..translate(
                            canvasModel.offset.dx,
                            canvasModel.offset.dy,
                          )
                          ..scale(canvasModel.scale),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 연결선을 노드들 뒤에 그리기
                            CustomPaint(
                              painter: ConnectionPainter(canvasModel),
                              size: Size.infinite,
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
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _handlePointerSignal(PointerSignalEvent event, CanvasModel canvasModel) {
    if (event is PointerScrollEvent) {
      final delta = event.scrollDelta.dy;
      canvasModel.scale = (canvasModel.scale - delta * 0.001).clamp(0.1, 3.0);
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, CanvasModel canvasModel) {
    canvasModel.offset = canvasModel.offset + details.delta;
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
    // 드롭된 위치를 캔버스 좌표로 변환
    final canvasPosition = details.offset - canvasModel.offset;
    final nodeType = details.data;

    // 새 노드 생성
    final newNode = NodeModel(
      id: 'node_${DateTime.now().millisecondsSinceEpoch}',
      type: nodeType,
      title: _getNodeTitle(nodeType),
      position: canvasPosition / canvasModel.scale,
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
    });
  }

  void _initializeTestNodes(CanvasModel canvasModel) {
    // 테스트용 노드 추가
    final sceneNode = NodeModel(
      id: 'test1',
      type: NodeType.scene,
      title: 'Video Scene',
      position: const Offset(100, 100),
    );
    sceneNode.addOutputPort('scene_out', 'Scene Output', color: Colors.blue);
    canvasModel.addNode(sceneNode);

    final actorNode = NodeModel(
      id: 'test2',
      type: NodeType.actor,
      title: 'Video Actor',
      position: const Offset(300, 200),
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
    for (
      double x = canvasModel.offset.dx % gridSize;
      x < size.width;
      x += gridSize
    ) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 수평선 그리기
    for (
      double y = canvasModel.offset.dy % gridSize;
      y < size.height;
      y += gridSize
    ) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
