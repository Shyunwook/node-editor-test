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

  // 드래그 상태 관리
  Offset? _dragStartPosition;
  Offset _accumulatedDelta = Offset.zero;

  // 포트 위치 측정 콜백
  void _onPortPositionMeasured(NodePort port, Offset relativePosition) {
    // 노드 내에서의 상대 위치를 포트에 저장
    port.relativePosition = relativePosition;
    
    // 캔버스 모델에 절대 위치 업데이트
    final canvasModel = context.read<CanvasModel>();
    final canvasPosition = port.getCanvasPosition(widget.node.position);
    canvasModel.updatePortPosition(widget.node.id, port.id, canvasPosition);
    
  }

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
          if (isInput) _buildMeasuredPortHandle(port),
          if (isInput) const SizedBox(width: 8),
          Text(
            port.label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (!isInput) const SizedBox(width: 8),
          if (!isInput) _buildMeasuredPortHandle(port),
        ],
      ),
    );
  }

  Widget _buildPortContainer(NodePort port, {Color? overrideColor, double? borderWidth}) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: overrideColor ?? port.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: borderWidth ?? 1,
        ),
      ),
    );
  }

  Widget _buildMeasuredPortHandle(NodePort port) {
    final canvasModel = context.read<CanvasModel>();
    final isOutput = widget.node.outputPorts.contains(port);

    if (isOutput) {
      // 출력 포트: Draggable로 드래그 시작
      return Draggable<Map<String, String>>(
        data: {'nodeId': widget.node.id, 'portId': port.id},
        onDragStarted: () {
          final canvasPosition = port.getCanvasPosition(widget.node.position);
          _dragStartPosition = canvasPosition;
          _accumulatedDelta = Offset.zero;
          canvasModel.startConnection(widget.node.id, port.id, canvasPosition);
        },
        onDragUpdate: (details) {
          final currentScale = canvasModel.scale;
          final adjustedDelta = details.delta / currentScale;
          _accumulatedDelta += adjustedDelta;
          final canvasPosition = _dragStartPosition! + _accumulatedDelta;
          canvasModel.updateTemporaryConnection(canvasPosition);
        },
        onDragEnd: (details) {
          _dragStartPosition = null;
          _accumulatedDelta = Offset.zero;
          canvasModel.cancelConnection();
        },
        feedback: Transform.scale(
          scale: canvasModel.scale,
          child: _buildPortContainer(port, overrideColor: Colors.red),
        ),
        child: MeasuredPortWidget(
          port: port,
          onPositionMeasured: _onPortPositionMeasured,
          child: _buildPortContainer(port),
        ),
      );
    } else {
      // 입력 포트: DragTarget으로 드롭 받기
      return DragTarget<Map<String, String>>(
        onAcceptWithDetails: (details) {
          canvasModel.completeConnection(widget.node.id, port.id);
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return MeasuredPortWidget(
            port: port,
            onPositionMeasured: _onPortPositionMeasured,
            child: _buildPortContainer(
              port,
              overrideColor: isHovering ? Colors.green : null,
              borderWidth: isHovering ? 2 : 1,
            ),
          );
        },
      );
    }
  }




  @override
  void initState() {
    super.initState();
  }
}

// 포트 위치를 측정하는 위젯
class MeasuredPortWidget extends StatefulWidget {
  final Widget child;
  final NodePort port;
  final Function(NodePort, Offset) onPositionMeasured;

  const MeasuredPortWidget({
    super.key,
    required this.child,
    required this.port,
    required this.onPositionMeasured,
  });

  @override
  State<MeasuredPortWidget> createState() => _MeasuredPortWidgetState();
}

class _MeasuredPortWidgetState extends State<MeasuredPortWidget> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measurePosition());
  }

  @override
  void didUpdateWidget(covariant MeasuredPortWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 위젯이 업데이트될 때마다 위치 재측정
    WidgetsBinding.instance.addPostFrameCallback((_) => _measurePosition());
  }

  void _measurePosition() {
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      // 노드 위젯의 렌더박스를 찾기
      RenderBox? nodeRenderBox;
      context.visitAncestorElements((element) {
        if (element.widget is NodeWidget) {
          nodeRenderBox = element.findRenderObject() as RenderBox?;
          return false;
        }
        return true;
      });
      
      if (nodeRenderBox != null) {
        // 스케일에 영향받지 않는 로컬 좌표계에서 계산
        final portLocalCenter = Offset(6, 6); // 포트 핸들의 로컬 중심 (12x12의 중심)
        final portPositionInNode = nodeRenderBox!.globalToLocal(
          renderBox.localToGlobal(portLocalCenter)
        );
        
        
        widget.onPositionMeasured(widget.port, portPositionInNode);
        return;
      }
      
      // 폴백: 기존 방식
      final center = Offset(6, 6); // 12x12 컨테이너의 중심
      widget.onPositionMeasured(widget.port, center);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
      child: widget.child,
    );
  }
}

