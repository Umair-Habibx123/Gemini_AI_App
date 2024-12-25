// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:gemini_ai_app/main.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:image_picker/image_picker.dart';

// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key});

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final List<XFile> _images = [];
//   final ImagePicker _picker = ImagePicker();
//   final List<Map<String, String>> _messages = [];
//   bool _isLoading = false;

//   Future<void> _pickImage() async {
//     final pickedFile = await _picker.pickImage(
//         source: ImageSource.gallery, preferredCameraDevice: CameraDevice.front);
//     if (pickedFile != null) {
//       setState(() {
//         _images.add(pickedFile);
//       });
//     }
//   }

//   Future<void> _sendMessage() async {
//     final message = _controller.text.trim();
//     if (message.isEmpty && _images.isEmpty) {
//       _showDialog('Please enter a message or select an image.');
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final response = await generateContent(message, _images);
//       setState(() {
//         if (message.isNotEmpty) {
//           _messages.add({'text': message, 'type': 'text'});
//         }
//         for (var image in _images) {
//           _messages.add({'text': image.path, 'type': 'image'});
//         }
//         _messages.add({'text': response, 'type': 'response'});
//         _controller.clear();
//         _images.clear();
//       });

//       _showSnackBar('Message sent successfully 😍 ', Colors.green);
//     } catch (e) {
//       _showSnackBar(
//           'Failed to send message. Server error or Internet error occurred!!! Try again later 😢',
//           Colors.red);
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<String> generateContent(String message, List<XFile> images) async {
//     final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey!);
//     final prompt = TextPart(message);
//     final imageParts = await Future.wait(
//       images.map((image) async => DataPart(
//             'image/jpeg',
//             await File(image.path).readAsBytes(),
//           )),
//     );

//     final response = await model.generateContent([
//       Content.multi([prompt, ...imageParts])
//     ]);

//     if (response.text != null) {
//       return response.text!;
//     } else {
//       _showSnackBar(
//           'Failed to generate content. Server error or Internet error occurred!!! Try again later  😢',
//           Colors.red);
//       throw Exception(
//           'Failed to generate content. Server error or Internet error occurred!!! Try again later  😢');
//     }
//   }

//   void _showSnackBar(String message, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         duration: const Duration(seconds: 2),
//         backgroundColor: color,
//       ),
//     );
//   }

//   void _showDialog(String message) {
//     showDialog<void>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Error'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: _buildAppBar(),
//       body: Column(
//         children: [
//           Expanded(child: _buildMessageList()),
//           if (_images.isNotEmpty) _buildImagePreview(),
//           _buildInputArea(),
//         ],
//       ),
//     );
//   }

//   AppBar _buildAppBar() {
//     return AppBar(
//       backgroundColor: const Color(0xFF7180AC),
//       title: const Text(
//         'Gemini AI App',
//         style: TextStyle(color: Colors.white),
//       ),
//       actions: [
//         PopupMenuButton(
//           onSelected: (value) {
//             if (value == 'exit') {
//               exit(1);
//             }
//           },
//           itemBuilder: (BuildContext context) => [
//             const PopupMenuItem(
//               value: 'exit',
//               child: Text('Exit App', style: TextStyle(color: Colors.black)),
//             ),
//           ],
//           icon: const Icon(Icons.more_vert, color: Colors.white),
//         ),
//       ],
//     );
//   }

//   ListView _buildMessageList() {
//     return ListView.builder(
//       itemCount: _messages.length,
//       itemBuilder: (context, index) {
//         final message = _messages[index];
//         switch (message['type']) {
//           case 'text':
//             return _buildTextMessage(message['text']!);
//           case 'image':
//             return _buildImageMessage(message['text']!);
//           case 'response':
//             return _buildResponseMessage(message['text']!);
//           default:
//             return Container();
//         }
//       },
//     );
//   }

//   Widget _buildTextMessage(String text) {
//     return ListTile(
//       leading: const CircleAvatar(
//         radius: 20,
//         backgroundImage: AssetImage('assets/user.png'),
//       ),
//       title: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//         decoration: BoxDecoration(
//           color: const Color(0xFF2B4570),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Text(
//           text,
//           style: const TextStyle(color: Colors.white),
//         ),
//       ),
//     );
//   }

//   Widget _buildImageMessage(String imagePath) {
//     return ListTile(
//       title: GestureDetector(
//         onTap: () {
//           showModalBottomSheet(
//             context: context,
//             builder: (BuildContext context) {
//               return SizedBox(
//                 height: MediaQuery.of(context).size.height * 0.8,
//                 child: PhotoView(
//                   imageProvider: FileImage(File(imagePath)),
//                   minScale: PhotoViewComputedScale.contained * 0.5,
//                   maxScale: PhotoViewComputedScale.covered * 2.0,
//                 ),
//               );
//             },
//           );
//         },
//         child: Container(
//           width: 200,
//           height: 200,
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey),
//           ),
//           child: Image.file(
//             File(imagePath),
//             fit: BoxFit.contain,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildResponseMessage(String response) {
//     return ListTile(
//       title: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//         decoration: BoxDecoration(
//           color: const Color(0xFFA8D0DB),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'AI Response: $response',
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 5),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.copy),
//                   onPressed: () {
//                     Clipboard.setData(ClipboardData(text: response));
//                     _showSnackBar('Text Copied successfully', Colors.green);
//                   },
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.share),
//                   onPressed: () {
//                     Share.share(response);
//                   },
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildImagePreview() {
//     return Container(
//       color: const Color(0xFFA37A74),
//       height: 75,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: _images.length,
//         itemBuilder: (context, index) {
//           return Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Stack(
//               children: [
//                 Container(
//                   width: 75,
//                   height: 75,
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey),
//                   ),
//                   child: Image.file(
//                     File(_images[index].path),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 Positioned(
//                   top: 0,
//                   right: 0,
//                   child: IconButton(
//                     icon: const Icon(
//                       Icons.close,
//                       color: Colors.black,
//                       size: 30.0,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _images.removeAt(index);
//                       });
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildInputArea() {
//     return Container(
//       color: const Color(0xFFA37A74),
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Row(
//           children: [
//             IconButton(
//               icon: const Icon(Icons.image, color: Colors.white),
//               onPressed: _isLoading ? null : _pickImage,
//             ),
//             Expanded(
//               child: TextField(
//                 controller: _controller,
//                 decoration: const InputDecoration(
//                   hintText: 'Enter text',
//                   hintStyle: TextStyle(color: Colors.white),
//                   enabledBorder: UnderlineInputBorder(
//                     borderSide: BorderSide(color: Colors.white),
//                   ),
//                   focusedBorder: UnderlineInputBorder(
//                     borderSide: BorderSide(color: Colors.blue),
//                   ),
//                 ),
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: _isLoading ? null : _sendMessage,
//               style: ElevatedButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 backgroundColor: const Color(0xFF7180AC),
//               ),
//               child: _isLoading
//                   ? const SizedBox(
//                       width: 24,
//                       height: 24,
//                       child: CircularProgressIndicator(
//                         color: Colors.white,
//                         strokeWidth: 2.0,
//                       ),
//                     )
//                   : const Text('Generate'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
