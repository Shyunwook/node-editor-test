import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/canvas_model.dart';
import '../../models/node_model.dart';

class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CanvasModel>(
      builder: (context, canvasModel, child) {
        final selectedNode = canvasModel.selectedNode;
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Properties',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (selectedNode == null)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No node selected',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: _buildNodeProperties(selectedNode),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _generateJSON(canvasModel);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                  ),
                  child: const Text('Generate JSON'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNodeProperties(NodeModel selectedNode) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Node Info', [
            _buildProperty('Type', selectedNode.type.name),
            _buildProperty('ID', selectedNode.id),
            _buildProperty('Title', selectedNode.title),
          ]),
          const SizedBox(height: 16),
          _buildSection('Position', [
            _buildProperty('X', selectedNode.position.dx.toStringAsFixed(1)),
            _buildProperty('Y', selectedNode.position.dy.toStringAsFixed(1)),
          ]),
          const SizedBox(height: 16),
          _buildSection('Ports', [
            _buildPortList('Input Ports', selectedNode.inputPorts),
            _buildPortList('Output Ports', selectedNode.outputPorts),
          ]),
        ],
      ),
    );
  }

  Widget _buildPortList(String title, List<NodePort> ports) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        if (ports.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Text(
              'None',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
            ),
          )
        else
          ...ports.map((port) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: port.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${port.label} (${port.id})',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          )),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildProperty(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: value,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _generateJSON(CanvasModel canvasModel) {
    // JSON 생성 로직 (나중에 구현)
    print('Generating JSON...');
    print('Nodes: ${canvasModel.nodes.length}');
    print('Connections: ${canvasModel.connections.length}');
    
    // 간단한 JSON 구조 출력
    final jsonData = {
      'nodes': canvasModel.nodes.map((node) => {
        'id': node.id,
        'type': node.type.name,
        'title': node.title,
        'position': {
          'x': node.position.dx,
          'y': node.position.dy,
        },
        'inputPorts': node.inputPorts.map((port) => {
          'id': port.id,
          'label': port.label,
        }).toList(),
        'outputPorts': node.outputPorts.map((port) => {
          'id': port.id,
          'label': port.label,
        }).toList(),
      }).toList(),
      'connections': canvasModel.connections.map((conn) => {
        'from': '${conn.fromNodeId}.${conn.fromPortId}',
        'to': '${conn.toNodeId}.${conn.toPortId}',
      }).toList(),
    };
    
    print('Generated JSON: $jsonData');
  }
}