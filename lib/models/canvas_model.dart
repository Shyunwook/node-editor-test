import 'package:flutter/material.dart';
import 'node_model.dart';

class CanvasModel extends ChangeNotifier {
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  final List<NodeModel> _nodes = [];
  final List<ConnectionModel> _connections = [];
  NodeModel? _selectedNode;
  
  // 연결 드래그 상태
  bool _isConnecting = false;
  String? _connectingFromNodeId;
  String? _connectingFromPortId;
  Offset? _temporaryConnectionStart;
  Offset? _temporaryConnectionEnd;
  
  // 실제 포트 위치 저장 (nodeId:portId -> position)
  final Map<String, Offset> _portPositions = {};

  Offset get offset => _offset;
  set offset(Offset value) {
    _offset = value;
    notifyListeners();
  }

  double get scale => _scale;
  set scale(double value) {
    _scale = value;
    notifyListeners();
  }

  List<NodeModel> get nodes => List.unmodifiable(_nodes);
  List<ConnectionModel> get connections => List.unmodifiable(_connections);
  NodeModel? get selectedNode => _selectedNode;
  
  // 연결 상태 getter
  bool get isConnecting => _isConnecting;
  String? get connectingFromNodeId => _connectingFromNodeId;
  String? get connectingFromPortId => _connectingFromPortId;
  Offset? get temporaryConnectionStart => _temporaryConnectionStart;
  Offset? get temporaryConnectionEnd => _temporaryConnectionEnd;

  // 포트 위치 관리
  void updatePortPosition(String nodeId, String portId, Offset position) {
    final key = '$nodeId:$portId';
    _portPositions[key] = position;
  }
  
  Offset? getPortPosition(String nodeId, String portId) {
    final key = '$nodeId:$portId';
    return _portPositions[key];
  }

  void setSelectedNode(NodeModel? node) {
    // 기존 선택 해제
    if (_selectedNode != null) {
      _selectedNode!.isSelected = false;
    }
    
    _selectedNode = node;
    
    // 새 노드 선택
    if (_selectedNode != null) {
      _selectedNode!.isSelected = true;
    }
    
    notifyListeners();
  }

  void addNode(NodeModel node) {
    _nodes.add(node);
    notifyListeners();
  }

  void removeNode(String nodeId) {
    _nodes.removeWhere((node) => node.id == nodeId);
    // 연관된 연결도 제거
    _connections.removeWhere(
      (conn) => conn.fromNodeId == nodeId || conn.toNodeId == nodeId,
    );
    notifyListeners();
  }

  void addConnection(ConnectionModel connection) {
    _connections.add(connection);
    notifyListeners();
  }

  void removeConnection(ConnectionModel connection) {
    _connections.remove(connection);
    notifyListeners();
  }

  NodeModel? getNodeById(String id) {
    try {
      return _nodes.firstWhere((node) => node.id == id);
    } catch (e) {
      return null;
    }
  }

  // 연결 드래그 시작
  void startConnection(String nodeId, String portId, Offset startPosition) {
    _isConnecting = true;
    _connectingFromNodeId = nodeId;
    _connectingFromPortId = portId;
    _temporaryConnectionStart = startPosition;
    _temporaryConnectionEnd = startPosition;
    notifyListeners();
  }

  // 임시 연결선 업데이트
  void updateTemporaryConnection(Offset endPosition) {
    if (_isConnecting) {
      _temporaryConnectionEnd = endPosition;
      notifyListeners();
    }
  }

  // 연결 완료
  void completeConnection(String toNodeId, String toPortId) {
    if (_isConnecting && _connectingFromNodeId != null && _connectingFromPortId != null) {
      // 유효성 검증
      if (_isValidConnection(_connectingFromNodeId!, _connectingFromPortId!, toNodeId, toPortId)) {
        addConnection(ConnectionModel(
          fromNodeId: _connectingFromNodeId!,
          fromPortId: _connectingFromPortId!,
          toNodeId: toNodeId,
          toPortId: toPortId,
        ));
      }
    }
    _cancelConnection();
  }

  // 연결 취소
  void _cancelConnection() {
    _isConnecting = false;
    _connectingFromNodeId = null;
    _connectingFromPortId = null;
    _temporaryConnectionStart = null;
    _temporaryConnectionEnd = null;
    notifyListeners();
  }

  void cancelConnection() {
    _cancelConnection();
  }

  // 연결 유효성 검증
  bool _isValidConnection(String fromNodeId, String fromPortId, String toNodeId, String toPortId) {
    // 같은 노드끼리는 연결 불가
    if (fromNodeId == toNodeId) return false;

    final fromNode = getNodeById(fromNodeId);
    final toNode = getNodeById(toNodeId);
    
    if (fromNode == null || toNode == null) return false;

    // 출력 포트에서 입력 포트로만 연결 가능한지 확인
    final hasFromPort = fromNode.outputPorts.any((port) => port.id == fromPortId);
    final hasToPort = toNode.inputPorts.any((port) => port.id == toPortId);
    
    if (!hasFromPort || !hasToPort) return false;

    // 이미 연결된 포트인지 확인
    final existingConnection = _connections.any((conn) => 
      (conn.fromNodeId == fromNodeId && conn.fromPortId == fromPortId) ||
      (conn.toNodeId == toNodeId && conn.toPortId == toPortId)
    );

    return !existingConnection;
  }
}

class ConnectionModel {
  final String fromNodeId;
  final String fromPortId;
  final String toNodeId;
  final String toPortId;

  ConnectionModel({
    required this.fromNodeId,
    required this.fromPortId,
    required this.toNodeId,
    required this.toPortId,
  });
}