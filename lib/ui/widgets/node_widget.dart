import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/node_model.dart';
import '../../models/canvas_model.dart';

class NodeWidget extends StatefulWidget {
  final NodeModel node;
  final Function(Offset) onPositionChanged;
  final VoidCallback? onTap;

  const NodeWidget({
    super.key,
    required this.node,
    required this.onPositionChanged,
    this.onTap,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  bool _isDragging = false;
  final Map<String, GlobalKey> _portKeys = {};

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) {
        setState(() {
          _isDragging = true;
          widget.node.isSelected = true;
        });
      },
      onPanUpdate: (details) {
        widget.onPositionChanged(widget.node.position + details.delta);
      },
      onPanEnd: (_) {
        setState(() {
          _isDragging = false;
        });
      },
      onTap: () {
        widget.onTap?.call();
      },
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: widget.node.nodeColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.node.isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: _isDragging
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 노드 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: Text(
                widget.node.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // 노드 바디
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // 입력 포트들
                  ...widget.node.inputPorts.map(
                    (port) => _buildPort(port, true),
                  ),
                  if (widget.node.inputPorts.isNotEmpty &&
                      widget.node.outputPorts.isNotEmpty)
                    const SizedBox(height: 8),
                  // 출력 포트들
                  ...widget.node.outputPorts.map(
                    (port) => _buildPort(port, false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPort(NodePort port, bool isInput) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isInput
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (isInput) _buildPortHandle(port),
          if (isInput) const SizedBox(width: 8),
          Text(
            port.label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (!isInput) const SizedBox(width: 8),
          if (!isInput) _buildPortHandle(port),
        ],
      ),
    );
  }

  Widget _buildPortHandle(NodePort port) {
    final canvasModel = context.read<CanvasModel>();
    final isOutput = widget.node.outputPorts.contains(port);

    // 포트별 GlobalKey 생성
    if (!_portKeys.containsKey(port.id)) {
      _portKeys[port.id] = GlobalKey();
    }
    final portKey = _portKeys[port.id]!;

    if (isOutput) {
      // 출력 포트: Draggable로 드래그 시작
      return Draggable<Map<String, String>>(
        data: {'nodeId': widget.node.id, 'portId': port.id},
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () {
          // 캔버스 좌표계에서의 포트 위치 계산
          final canvasPosition = _getPortCanvasPosition(port);
          print('🔵 [DRAG_START] Port: ${port.label}');
          print('🔵 [DRAG_START] Canvas Position: $canvasPosition');
          canvasModel.startConnection(widget.node.id, port.id, canvasPosition);
        },
        onDragUpdate: (details) {
          final canvasModel = context.read<CanvasModel>();

          // InteractiveViewer 내부에서는 localPosition을 사용 (자동 변환됨)
          final canvasPosition = details.localPosition;

          print('🟡 [DRAG_UPDATE] Global Position: ${details.globalPosition}');  
          print('🟡 [DRAG_UPDATE] Local Position: ${details.localPosition}');
          print('🟡 [DRAG_UPDATE] Canvas Position (InteractiveViewer): $canvasPosition');
          canvasModel.updateTemporaryConnection(canvasPosition);
        },
        onDragEnd: (details) {
          canvasModel.cancelConnection();
        },
        feedback: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: port.color.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        child: Container(
          key: portKey,
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: port.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
      );
    } else {
      // 입력 포트: DragTarget으로 드롭 받기
      return DragTarget<Map<String, String>>(
        onAcceptWithDetails: (details) {
          canvasModel.completeConnection(widget.node.id, port.id);
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            key: portKey,
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty ? Colors.green : port.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: candidateData.isNotEmpty ? Colors.white : Colors.white,
                width: candidateData.isNotEmpty ? 2 : 1,
              ),
            ),
          );
        },
      );
    }
  }

  /// 캔버스 좌표계에서 포트 위치를 계산합니다
  Offset _getPortCanvasPosition(NodePort port) {
    // 노드 위치 기준으로 포트 상대 위치 계산
    double currentY = 32.0 + 8.0; // headerHeight + padding

    // 입력 포트들 처리
    for (int i = 0; i < widget.node.inputPorts.length; i++) {
      if (widget.node.inputPorts[i] == port) {
        final portCenterY = currentY + 2.0 + 6.0; // margin + handle center
        return Offset(
          widget.node.position.dx + 8.0 + 6.0,
          widget.node.position.dy + portCenterY,
        );
      }
      currentY += 16.0;
    }

    // 포트 간 간격
    if (widget.node.inputPorts.isNotEmpty &&
        widget.node.outputPorts.isNotEmpty) {
      currentY += 8.0;
    }

    // 출력 포트들 처리
    for (int i = 0; i < widget.node.outputPorts.length; i++) {
      if (widget.node.outputPorts[i] == port) {
        final portCenterY = currentY + 2.0 + 6.0; // margin + handle center
        return Offset(
          widget.node.position.dx + 200.0 - 8.0 - 6.0,
          widget.node.position.dy + portCenterY,
        );
      }
      currentY += 16.0;
    }

    return widget.node.position; // fallback
  }

  @override
  void initState() {
    super.initState();
    // 포트 위치를 정기적으로 업데이트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAllPortPositions();
    });
  }

  void _updateAllPortPositions() {
    final canvasModel = context.read<CanvasModel>();

    // 모든 포트 위치 업데이트
    for (final port in [
      ...widget.node.inputPorts,
      ...widget.node.outputPorts,
    ]) {
      final portKey = _portKeys[port.id];
      if (portKey != null && portKey.currentContext != null) {
        final renderBox =
            portKey.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final size = renderBox.size;
          final localCenter = Offset(size.width / 2, size.height / 2);
          final globalPosition = renderBox.localToGlobal(localCenter);
          canvasModel.updatePortPosition(
            widget.node.id,
            port.id,
            globalPosition,
          );
        }
      }
    }
  }
}
