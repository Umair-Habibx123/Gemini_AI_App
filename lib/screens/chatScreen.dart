import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:gemini_ai_app/DB/SQLiteHelper.dart';
import 'package:gemini_ai_app/main.dart';
import 'package:gemini_ai_app/widgets/AppBar.dart';
import 'package:gemini_ai_app/widgets/ImagePreview.dart';
import 'package:gemini_ai_app/widgets/InputArea.dart';
import 'package:gemini_ai_app/widgets/MessageList.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final int? chatId; // Chat ID for current chat context
  final String? chatName;

  const ChatScreen({super.key, this.chatId, this.chatName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<XFile> _images = [];
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  int? _currentChatId;

  @override
  void initState() {
    super.initState();
    _currentChatId = widget.chatId;
    if (_currentChatId != null) {
      _loadMessages(_currentChatId!);
    }
  }

  Future<void> _loadMessages(int chatId) async {
    final messages = await ChatDatabaseHelper.instance.getMessages(chatId);
    setState(() {
      _messages.clear();
      _messages.addAll(messages.map((msg) {
        return {
          'text': msg['text'],
          'type': msg['type'], // This ensures the message type is preserved
        };
      }));
    });
  }

  Future<int> _createNewChat() async {
    final chats = await ChatDatabaseHelper.instance.getChats();
    final now = DateTime.now();
    final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final nextChatNumber =
        chats.length + 1; // Increment by 1 for the new chat name

    // Generate a random string of letters and numbers
    final randomString = _generateRandomString(6); // You can change the length
    final chatId =
        '$randomString-$nextChatNumber'; // Combines random string with the chat number

    final chatIdInserted = await ChatDatabaseHelper.instance.insertChat({
      'name': 'Chat $chatId', // Use the random, readable chat ID
      'created_at': formattedDateTime,
    });

    setState(() {
      _currentChatId = chatIdInserted;
    });

    _loadMessages(chatIdInserted);

    return chatIdInserted;
  }

// Helper function to generate a random string
  String _generateRandomString(int length) {
    const _chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random _rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }

  // Define helper methods like _pickImage(), _sendMessage(), etc.

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, preferredCameraDevice: CameraDevice.front);
    if (pickedFile != null) {
      setState(() {
        _images.add(pickedFile);
      });
    }
  }

  void _showDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty && _images.isEmpty) {
      _showDialog('Please enter a message or select an image.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final message = _controller.text.trim();
      int chatId = _currentChatId ?? await _createNewChat();

      // Save user message to the database
      if (message.isNotEmpty) {
        await ChatDatabaseHelper.instance.insertMessage({
          'chat_id': chatId,
          'text': message,
          'type': 'text',
          'created_at': DateTime.now().toString(),
        });
      }

      for (var image in _images) {
        await ChatDatabaseHelper.instance.insertMessage({
          'chat_id': chatId,
          'text': image.path,
          'type': 'image',
          'created_at': DateTime.now().toString(),
        });
      }

      // Fetch AI-generated response
      final response = await generateContent(message, _images);

      // Save AI response to the database
      await ChatDatabaseHelper.instance.insertMessage({
        'chat_id': chatId,
        'text': response,
        'type': 'response',
        'created_at': DateTime.now().toString(),
      });

      setState(() {
        if (message.isNotEmpty) {
          _messages.add({'text': message, 'type': 'text'});
        }
        for (var image in _images) {
          _messages.add({'text': image.path, 'type': 'image'});
        }
        _messages.add({'text': response, 'type': 'response'});
        _controller.clear();
        _images.clear();
      });

      _showSnackBar('Message sent successfully 😍', Colors.green);
    } catch (e) {
      _showSnackBar(
          'Failed to send message. Please try again later 😢', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchChats() async {
    final chats = await ChatDatabaseHelper.instance.getChats();
    return chats;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: color,
      ),
    );
  }

  Future<String> generateContent(String message, List<XFile> images) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey!);
    final prompt = TextPart(message);
    final imageParts = await Future.wait(
      images.map((image) async => DataPart(
            'image/jpeg',
            await File(image.path).readAsBytes(),
          )),
    );

    final response = await model.generateContent([
      Content.multi([prompt, ...imageParts])
    ]);

    if (response.text != null) {
      return response.text!;
    } else {
      _showSnackBar(
          'Failed to generate content. Server error or Internet error occurred!!! Try again later  😢',
          Colors.red);
      throw Exception(
          'Failed to generate content. Server error or Internet error occurred!!! Try again later  😢');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        onExit: () => exit(1),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade800,
              ),
              child: const Center(
                child: Text(
                  'Chats',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text(
                'New Chat',
                style: TextStyle(fontSize: 16),
              ),
              leading: const Icon(Icons.chat, color: Colors.blueGrey),
              onTap: () {
                // Close the drawer
                Navigator.pop(context);
                // Perform the action for creating a new chat
                _createNewChat();
              },
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: ChatDatabaseHelper.instance.getChats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No chats available.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final chat = snapshot.data![index];
                      final createdAt = chat['created_at'] ?? '';

                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline),
                        title: Text(
                          chat['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            createdAt,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () {
                                // Show a confirmation dialog before deleting
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Chat'),
                                    content: const Text(
                                        'Are you sure you want to delete this chat?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          // Delete chat from the database
                                          await ChatDatabaseHelper.instance
                                              .deleteChat(chat['id']);
                                          // Close the dialog
                                          Navigator.pop(context);
                                          // Remove chat from the UI
                                          setState(() {
                                            // Set currentChatId to null to reset the UI
                                            _currentChatId = null;
                                            _messages
                                                .clear(); // Clear the messages
                                          });
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: chat['id'],
                                chatName: chat['name'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: MessageList(messages: _messages)),
          if (_images.isNotEmpty)
            ImagePreviewList(
              images: _images,
              onRemoveImage: (index) => setState(() {
                _images.removeAt(index);
              }),
            ),
          InputArea(
            controller: _controller,
            isLoading: _isLoading,
            onPickImage: _pickImage,
            onSendMessage: _sendMessage,
          ),
        ],
      ),
    );
  }
}
