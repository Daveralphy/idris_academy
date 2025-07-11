import 'package:flutter/material.dart';
import 'package:idris_academy/support_page.dart';

class DraggableSupportButton extends StatefulWidget {
  // We now accept the parent constraints to correctly calculate position.
  final BoxConstraints parentConstraints;

  const DraggableSupportButton({super.key, required this.parentConstraints});

  @override
  State<DraggableSupportButton> createState() => _DraggableSupportButtonState();
}

class _DraggableSupportButtonState extends State<DraggableSupportButton> {
  // The position is now initialized directly in initState, as we have the constraints.
  late Offset _position;
  static const double _fabSize = 56.0;

  @override
  void initState() {
    super.initState();
    // This is where the initial position is now explicitly set to the bottom right.
    // It uses the constraints passed from the parent widget.
    _position = Offset(
      widget.parentConstraints.maxWidth - _fabSize - 16.0,
      widget.parentConstraints.maxHeight - _fabSize - 16.0,
    );
  }

  void _showSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the modal to take up more screen height
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // We can constrain the height to avoid it taking the full screen on very tall devices.
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A small grab handle for the modal
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // The header for the support modal
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Support Chat',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // The actual support page content
                const Expanded(
                  child: SupportPage(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // The widget now directly returns a Positioned widget, which is the correct
    // way to place an item within a Stack.
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            // Update the position by the change in drag distance (delta).
            // The new position is clamped to ensure it stays within the screen bounds.
            double newDx = (_position.dx + details.delta.dx).clamp(0.0, widget.parentConstraints.maxWidth - _fabSize);
            double newDy = (_position.dy + details.delta.dy).clamp(0.0, widget.parentConstraints.maxHeight - _fabSize);
            _position = Offset(newDx, newDy);
          });
        },
        child: FloatingActionButton(onPressed: () => _showSupportModal(context), tooltip: 'Contact Support', child: const Icon(Icons.headset_mic_outlined)),
      ),
    );
  }
}
