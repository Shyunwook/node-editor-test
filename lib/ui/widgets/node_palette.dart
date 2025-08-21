import 'package:flutter/material.dart';
import '../../models/node_model.dart';

class NodePalette extends StatelessWidget {
  const NodePalette({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[850],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Node Palette',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildNodeTypeSection('Scene', [
                  _NodePaletteItem(
                    title: 'Video Scene',
                    type: NodeType.scene,
                    icon: Icons.video_library,
                  ),
                ]),
                _buildNodeTypeSection('Actors', [
                  _NodePaletteItem(
                    title: 'Video Actor',
                    type: NodeType.actor,
                    icon: Icons.play_circle,
                  ),
                  _NodePaletteItem(
                    title: 'Image Actor',
                    type: NodeType.actor,
                    icon: Icons.image,
                  ),
                ]),
                _buildNodeTypeSection('Detectors', [
                  _NodePaletteItem(
                    title: 'Tap Detector',
                    type: NodeType.detector,
                    icon: Icons.touch_app,
                  ),
                  _NodePaletteItem(
                    title: 'Drag Detector',
                    type: NodeType.detector,
                    icon: Icons.pan_tool,
                  ),
                ]),
                _buildNodeTypeSection('Logic', [
                  _NodePaletteItem(
                    title: 'Combine AND',
                    type: NodeType.combine,
                    icon: Icons.call_merge,
                  ),
                  _NodePaletteItem(
                    title: 'Combine OR',
                    type: NodeType.combine,
                    icon: Icons.call_split,
                  ),
                ]),
                _buildNodeTypeSection('Actions', [
                  _NodePaletteItem(
                    title: 'Play Video',
                    type: NodeType.action,
                    icon: Icons.play_arrow,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeTypeSection(String title, List<_NodePaletteItem> items) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      iconColor: Colors.white70,
      collapsedIconColor: Colors.white70,
      children: items,
    );
  }
}

class _NodePaletteItem extends StatelessWidget {
  final String title;
  final NodeType type;
  final IconData icon;

  const _NodePaletteItem({
    required this.title,
    required this.type,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<NodeType>(
      data: type,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getNodeColor(type),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNodeColor(NodeType type) {
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
}