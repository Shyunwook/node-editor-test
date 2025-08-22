import 'package:flutter/material.dart';

enum NodeType {
  scene,
  actor,
  detector,
  combine,
  action,
}

enum PortType {
  input,
  output,
}

class NodeModel extends ChangeNotifier {
  final String id;
  final NodeType type;
  final String title;
  Offset _position;
  bool isSelected;
  final List<NodePort> inputPorts;
  final List<NodePort> outputPorts;
  final Map<String, dynamic> properties;

  NodeModel({
    required this.id,
    required this.type,
    required this.title,
    required Offset position,
    this.isSelected = false,
    List<NodePort>? inputPorts,
    List<NodePort>? outputPorts,
    Map<String, dynamic>? properties,
  }) : _position = position,
       inputPorts = inputPorts ?? [],
       outputPorts = outputPorts ?? [],
       properties = properties ?? {};

  Offset get position => _position;
  set position(Offset value) {
    _position = value;
    notifyListeners();
  }

  Color get nodeColor {
    switch (type) {
      case NodeType.scene:
        return Colors.blue[700]!;
      case NodeType.actor:
        return Colors.green[700]!;
      case NodeType.detector:
        return Colors.orange[700]!;
      case NodeType.combine:
        return Colors.purple[700]!;
      case NodeType.action:
        return Colors.red[700]!;
    }
  }

  void addInputPort(String id, String label, {Color? color}) {
    inputPorts.add(NodePort(
      id: id,
      label: label,
      type: PortType.input,
      color: color ?? Colors.grey,
    ));
  }

  void addOutputPort(String id, String label, {Color? color}) {
    outputPorts.add(NodePort(
      id: id,
      label: label,
      type: PortType.output,
      color: color ?? Colors.grey,
    ));
  }
}

class NodePort {
  final String id;
  final String label;
  final PortType type;
  final Color color;
  Offset? position; // 글로벌 포지션
  Offset? relativePosition; // 노드 내에서의 상대 위치

  NodePort({
    required this.id,
    required this.label,
    required this.type,
    required this.color,
    this.position,
    this.relativePosition,
  });

  // 노드 위치를 기준으로 캔버스 절대 좌표 계산
  Offset getCanvasPosition(Offset nodePosition) {
    if (relativePosition == null) return nodePosition;
    return nodePosition + relativePosition!;
  }
}