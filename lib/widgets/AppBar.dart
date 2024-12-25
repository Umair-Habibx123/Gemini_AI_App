import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onExit;

  const ChatAppBar({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF7180AC),
      title: const Text(
        'Gemini AI App',
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        PopupMenuButton(
          onSelected: (value) {
            if (value == 'exit') onExit();
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'exit',
              child: Text('Exit App', style: TextStyle(color: Colors.black)),
            ),
          ],
          icon: const Icon(Icons.more_vert, color: Colors.white),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
