import 'package:flutter/material.dart';
import '../models/node_model.dart';
import '../models/canvas_model.dart';

class PortPositionCalculator {
  static const double nodeWidth = 200.0;
  static const double headerHeight = 32.0; // 실제 헤더 높이 (패딩 8 + 텍스트)
  static const double portVerticalMargin = 2.0; // Container margin
  static const double portHandleSize = 12.0; // 포트 핸들 크기
  static const double nodeBodyPadding = 8.0;

  /// 포트의 글로벌 위치를 계산합니다
  static Offset getPortGlobalPosition(
    NodeModel node, 
    NodePort port, 
    CanvasModel canvasModel
  ) {
    final isInput = node.inputPorts.contains(port);
    
    // 캔버스 변환 적용
    final transformedNodeX = (node.position.dx * canvasModel.scale) + canvasModel.offset.dx;
    final transformedNodeY = (node.position.dy * canvasModel.scale) + canvasModel.offset.dy;
    
    // 포트의 로컬 위치 계산
    final localPortPosition = _getLocalPortPosition(node, port, isInput);
    
    // 최종 글로벌 위치 계산
    final portX = transformedNodeX + (localPortPosition.dx * canvasModel.scale);
    final portY = transformedNodeY + (localPortPosition.dy * canvasModel.scale);
    
    return Offset(portX, portY);
  }

  /// 노드 내에서 포트의 로컬 위치를 계산합니다
  static Offset _getLocalPortPosition(NodeModel node, NodePort port, bool isInput) {
    double currentY = headerHeight + nodeBodyPadding;
    
    // 입력 포트들을 먼저 처리
    for (int i = 0; i < node.inputPorts.length; i++) {
      if (node.inputPorts[i] == port) {
        // 입력 포트: 왼쪽 패딩 + 핸들 중앙
        final portCenterY = currentY + portVerticalMargin + (portHandleSize / 2);
        return Offset(nodeBodyPadding + (portHandleSize / 2), portCenterY);
      }
      currentY += portHandleSize + (portVerticalMargin * 2); // handle + top/bottom margins
    }
    
    // 입력과 출력 포트 사이 간격
    if (node.inputPorts.isNotEmpty && node.outputPorts.isNotEmpty) {
      currentY += 8.0;
    }
    
    // 출력 포트들 처리
    for (int i = 0; i < node.outputPorts.length; i++) {
      if (node.outputPorts[i] == port) {
        // 출력 포트: 오른쪽 패딩에서 핸들 중앙만큼 뺀 위치
        final portCenterY = currentY + portVerticalMargin + (portHandleSize / 2);
        return Offset(nodeWidth - nodeBodyPadding - (portHandleSize / 2), portCenterY);
      }
      currentY += portHandleSize + (portVerticalMargin * 2); // handle + top/bottom margins
    }
    
    return Offset.zero; // 포트를 찾지 못한 경우
  }
}