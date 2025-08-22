import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/canvas_model.dart';

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

        // 새로운 시스템: 포트의 캔버스 절대 위치 사용
        final startPoint = fromPort.getCanvasPosition(fromNode.position);
        final endPoint = toPort.getCanvasPosition(toNode.position);


        _drawBezierCurve(canvas, paint, startPoint, endPoint, showArrow: true);
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

      _drawBezierCurve(canvas, paint, startPoint, endPoint, showArrow: false);

      // 임시 연결선 끝에 포트 모양 원 그리기
      _drawPortCircle(canvas, endPoint);
    }
  }

  void _drawBezierCurve(
    Canvas canvas,
    Paint paint,
    Offset start,
    Offset end, {
    bool showArrow = false,
  }) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // 베지어 곡선의 제어점 계산
    final controlPointDistance = (end.dx - start.dx).abs() * 0.5;
    final cp1 = Offset(start.dx + controlPointDistance, start.dy);
    final cp2 = Offset(end.dx - controlPointDistance, end.dy);

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
    canvas.drawPath(path, paint);

    // 화살표 그리기 (필요한 경우만)
    if (showArrow) {
      _drawArrow(canvas, paint, cp2, end);
    }
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset control, Offset end) {
    final direction = (end - control).direction;
    const arrowLength = 10.0;
    const arrowAngle = 0.5;

    final arrowPoint1 =
        end +
        Offset(
          arrowLength * math.cos(direction + math.pi - arrowAngle),
          arrowLength * math.sin(direction + math.pi - arrowAngle),
        );

    final arrowPoint2 =
        end +
        Offset(
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

  void _drawPortCircle(Canvas canvas, Offset position) {
    final portPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 포트 원 그리기
    canvas.drawCircle(position, 6.0, portPaint);
    canvas.drawCircle(position, 6.0, borderPaint);
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
