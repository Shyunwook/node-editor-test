import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/canvas_model.dart';
import '../../models/node_model.dart';
import '../../utils/port_position_calculator.dart';

class ConnectionPainter extends CustomPainter {
  final CanvasModel canvasModel;

  ConnectionPainter(this.canvasModel);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 기존 연결선들 그리기
    for (final connection in canvasModel.connections) {
      final fromNode = canvasModel.getNodeById(connection.fromNodeId);
      final toNode = canvasModel.getNodeById(connection.toNodeId);
      
      if (fromNode != null && toNode != null) {
        final fromPort = fromNode.outputPorts.firstWhere(
          (port) => port.id == connection.fromPortId,
        );
        final toPort = toNode.inputPorts.firstWhere(
          (port) => port.id == connection.toPortId,
        );

        // 캔버스 내부 좌표계로 포트 위치 계산
        final startPoint = _getPortCanvasPosition(fromNode, fromPort, canvasModel);
        final endPoint = _getPortCanvasPosition(toNode, toPort, canvasModel);

        _drawBezierCurve(canvas, paint, startPoint, endPoint);
      }
    }

    // 임시 연결선 그리기 (드래그 중)
    if (canvasModel.isConnecting && 
        canvasModel.temporaryConnectionStart != null && 
        canvasModel.temporaryConnectionEnd != null) {
      paint.color = Colors.grey;
      paint.strokeWidth = 3.0;
      
      // 시작점과 끝점 모두 이미 캔버스 좌표계
      final startPoint = canvasModel.temporaryConnectionStart!;
      final endPoint = canvasModel.temporaryConnectionEnd!;
      
      print('🟢 [CONNECTION_DRAW] Start Point: $startPoint');
      print('🟢 [CONNECTION_DRAW] End Point: $endPoint');
      
      _drawBezierCurve(canvas, paint, startPoint, endPoint);
    }
  }

  void _drawBezierCurve(Canvas canvas, Paint paint, Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // 베지어 곡선의 제어점 계산
    final controlPointDistance = (end.dx - start.dx).abs() * 0.5;
    final cp1 = Offset(start.dx + controlPointDistance, start.dy);
    final cp2 = Offset(end.dx - controlPointDistance, end.dy);

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
    canvas.drawPath(path, paint);

    // 화살표 그리기
    _drawArrow(canvas, paint, cp2, end);
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset control, Offset end) {
    final direction = (end - control).direction;
    const arrowLength = 10.0;
    const arrowAngle = 0.5;

    final arrowPoint1 = end + Offset(
      arrowLength * math.cos(direction + math.pi - arrowAngle),
      arrowLength * math.sin(direction + math.pi - arrowAngle),
    );

    final arrowPoint2 = end + Offset(
      arrowLength * math.cos(direction + math.pi + arrowAngle),
      arrowLength * math.sin(direction + math.pi + arrowAngle),
    );

    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy);

    canvas.drawPath(arrowPath, paint);
  }



  /// 캔버스 내부 좌표계에서 포트 위치를 계산합니다
  Offset _getPortCanvasPosition(NodeModel node, NodePort port, CanvasModel canvasModel) {
    // 노드 위치 (Transform이 적용된 좌표계)
    double currentY = 40.0 + 8.0; // headerHeight + padding
    
    // 입력 포트들 처리
    for (int i = 0; i < node.inputPorts.length; i++) {
      if (node.inputPorts[i] == port) {
        final portCenterY = currentY + 2.0 + 6.0; // margin + handle center
        return Offset(node.position.dx + 8.0 + 6.0, node.position.dy + portCenterY);
      }
      currentY += 16.0;
    }
    
    // 포트 간 간격
    if (node.inputPorts.isNotEmpty && node.outputPorts.isNotEmpty) {
      currentY += 8.0;
    }
    
    // 출력 포트들 처리
    for (int i = 0; i < node.outputPorts.length; i++) {
      if (node.outputPorts[i] == port) {
        final portCenterY = currentY + 2.0 + 6.0; // margin + handle center
        return Offset(node.position.dx + 200.0 - 8.0 - 6.0, node.position.dy + portCenterY);
      }
      currentY += 16.0;
    }
    
    return node.position; // fallback
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}