import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const WhatIfApp());
}

class WhatIfApp extends StatelessWidget {
  const WhatIfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatIf',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFF1A1A1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1A1A1A),
          secondary: Color(0xFF333333),
          surface: Color(0xFF1A1A1A),
          onPrimary: Color(0xFFEEEEEE),
          onSecondary: Color(0xFFEEEEEE),
          onSurface: Color(0xFFEEEEEE),
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: const Color(0xFFEEEEEE),
            displayColor: const Color(0xFFEEEEEE),
          ),
        ),
      ),
      home: const WhatIfHomePage(),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
  });
}

class WhatIfHomePage extends StatefulWidget {
  const WhatIfHomePage({super.key});

  @override
  State<WhatIfHomePage> createState() => _WhatIfHomePageState();
}

class _WhatIfHomePageState extends State<WhatIfHomePage> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speechToText = SpeechToText();
  final ImagePicker _imagePicker = ImagePicker();
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Add welcome message
    _addMessage(
      "Welcome to WhatIf! Ask me any 'what if' question and I'll create an alternate timeline for you. 🚀",
      false,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addMessage(String text, bool isUser, {String? imagePath}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
        imagePath: imagePath,
      ));
    });
    
    _scrollToBottom();
    
    if (!isUser) {
      _animationController.forward();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _addMessage(text, true);
    _textController.clear();
    
    setState(() {
      _isLoading = true;
    });

    try {
      String response = await _generateWhatIfResponse(text);
      if (mounted) {
        _addMessage(response, false);
      }
    } catch (e) {
      if (mounted) {
        _addMessage(
          "Sorry, I'm having trouble connecting right now. Here's a fun offline scenario:\n\n"
          "What if you discovered you could speak to plants? 🌱\n"
          "• 2024: Your houseplants start responding to your conversations\n"
          "• 2025: You become a plant whisperer, helping gardens grow everywhere\n"
          "• 2026: Scientists study your unique ability\n"
          "• 2027: You open a plant therapy center\n"
          "• 2028: The world becomes greener, one conversation at a time\n\n"
          "Sometimes the most magical things happen when we least expect them. 🌿",
          false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _generateWhatIfResponse(String prompt) async {
    const String huggingFaceApiKey = 'YOUR_HF_API_KEY'; // Replace with your HuggingFace API key
    const String apiUrl = 'https://api-inference.huggingface.co/models/HuggingFaceH4/zephyr-7b-beta';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $huggingFaceApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': 'What if $prompt? Write a fictional, emotional timeline in bullet points with emojis and a twist ending.',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // HuggingFace returns a List
      if (data is List && data.isNotEmpty && data[0]['generated_text'] != null) {
        return data[0]['generated_text'];
      } else {
        return "I couldn't generate a story this time. Please try a different 'what if'!";
      }
    } else {
      print("❌ API Error: ${response.statusCode}");
      print("❌ Body: ${response.body}");
      throw Exception('Failed to generate response');
    }
  }

  Future<void> _startVoiceInput() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for voice input')),
        );
      }
      return;
    }

    if (!_speechToText.isAvailable) {
      await _speechToText.initialize();
    }

    setState(() {
      _isListening = true;
    });

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() {
            _isListening = false;
          });
          if (result.recognizedWords.isNotEmpty) {
            _sendMessage(result.recognizedWords);
          }
        }
      },
    );
  }

  Future<void> _stopVoiceInput() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _pickImage() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required for image upload')),
        );
      }
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        _addMessage("📸 Analyzing this image...", true, imagePath: image.path);
        
        setState(() {
          _isLoading = true;
        });

        try {
          // The image itself is not sent, but the action triggers a text-based scenario
          String response = await _generateImageResponse();
          if (mounted) {
            _addMessage(response, false);
          }
        } catch (e) {
          if (mounted) {
            _addMessage(
              "Sorry, I couldn't analyze that image. Try asking me a 'what if' question instead! 🤔",
              false,
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  Future<String> _generateImageResponse() async {
    // Since the new model is text-only, we send a fixed prompt for the image feature.
    const String imagePrompt = "this picture was the first day of a different life";
    return _generateWhatIfResponse(imagePrompt);
  }

  void _saveToFavorites(String message) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorites') ?? [];
    favorites.add(message);
    await prefs.setStringList('favorites', favorites);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to favorites! 💾')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: Text(
          'WhatIf',
          style: GoogleFonts.inter(
            color: const Color(0xFFEEEEEE),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 48,
      ),
      body: Column(
        children: [
          // Chat Area
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingMessage();
                }
                final message = _messages[index];
                return _buildChatBubble(message);
              },
            ),
          ),
          // Input Bar
          SafeArea(
            top: false,
            child: Container(
              color: const Color(0xFF111111),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Voice Button
                  GestureDetector(
                    onTapDown: (_) => _startVoiceInput(),
                    onTapUp: (_) => _stopVoiceInput(),
                    onTapCancel: () => _stopVoiceInput(),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2, right: 2),
                      child: Icon(
                        Icons.mic,
                        color: _isListening ? const Color(0xFF4CAF50) : const Color(0xFF888888),
                        size: 24,
                      ),
                    ),
                  ),
                  // Image Button
                  GestureDetector(
                    onTap: _pickImage,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2, right: 6, left: 6),
                      child: Icon(
                        Icons.image,
                        color: const Color(0xFF888888),
                        size: 24,
                      ),
                    ),
                  ),
                  // Text Input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF23272F),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF23272F)),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFEEEEEE),
                          fontSize: 16,
                        ),
                        minLines: 1,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Type your what if…',
                          hintStyle: TextStyle(color: Color(0xFF888888)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send Button
                  GestureDetector(
                    onTap: () => _sendMessage(_textController.text),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _textController.text.trim().isEmpty ? const Color(0xFF23272F) : const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send,
                        color: _textController.text.trim().isEmpty ? const Color(0xFF888888) : Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isUser ? const Color(0xFF23272F) : const Color(0xFF181A20);
    final textColor = isUser ? const Color(0xFFEEEEEE) : const Color(0xFFEEEEEE);
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(10),
      topRight: const Radius.circular(10),
      bottomLeft: isUser ? const Radius.circular(10) : const Radius.circular(2),
      bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(10),
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        margin: EdgeInsets.only(
          left: isUser ? 40 : 12,
          right: isUser ? 12 : 40,
          top: 2,
          bottom: 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
          border: Border.all(color: const Color(0xFF23272F), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imagePath != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF23272F)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(message.imagePath!),
                    width: 200,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            SelectableText(
              message.text,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            if (!isUser) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => _saveToFavorites(message.text),
                    child: const Icon(
                      Icons.bookmark_border,
                      color: Color(0xFF888888),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share feature coming soon! 📤')),
                      );
                    },
                    child: const Icon(
                      Icons.share,
                      color: Color(0xFF888888),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        margin: const EdgeInsets.only(left: 12, right: 40, top: 2, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF181A20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF23272F), width: 1),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.grey[400]!,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Creating your alternate timeline...',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
