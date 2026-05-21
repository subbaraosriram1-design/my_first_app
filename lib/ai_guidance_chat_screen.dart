import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_service.dart';
import 'firebase_service.dart';

class AiGuidanceChatScreen extends StatefulWidget {
  const AiGuidanceChatScreen({super.key});

  @override
  State<AiGuidanceChatScreen> createState() => _AiGuidanceChatScreenState();
}

class _AiGuidanceChatScreenState extends State<AiGuidanceChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final AiService _aiService = GroqAiService();
  bool _isLoading = false;
  String? _selectedReason;
  int _messageCount = 0;
  static const int _maxMessages = 3;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'isUser': false,
      'text': 'Hello! To provide the best career guidance, please choose your primary reason for chatting today:',
      'time': DateTime.now(),
    });
  }

  void _selectReason(String reason) {
    setState(() {
      _selectedReason = reason;
      _messages.add({
        'isUser': true,
        'text': reason,
        'time': DateTime.now(),
      });
      _isLoading = true;
    });

    _fetchAiResponse(reason);
  }

  Future<void> _fetchAiResponse(String text) async {
    try {
      final userId = FirebaseService.instance.currentUserId;
      final userData = await FirebaseService.instance.getResume(userId ?? "");
      
      final response = await _aiService.getChatResponse(text, userData ?? {});

      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': response,
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': 'Sorry, I encountered an error. Please try again later.',
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty || _isLoading || _messageCount >= _maxMessages) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'time': DateTime.now(),
      });
      _messageController.clear();
      _isLoading = true;
      _messageCount++;
    });

    _scrollToBottom();
    await _fetchAiResponse(text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('AI Guidance', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            if (_selectedReason == null) _buildReasonSelection(),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                ),
              ),
            if (_selectedReason != null) _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _reasonButton('College Admission Strategy', 'How can I get into my dream college with my current profile?'),
          const SizedBox(height: 12),
          _reasonButton('Skill Acquisition Path', 'How can I master a specific new skill given my current background?'),
        ],
      ),
    );
  }

  Widget _reasonButton(String title, String fullText) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _selectReason(fullText),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
          foregroundColor: const Color(0xFF10B981),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF10B981), width: 1)),
        ),
        child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isUser = message['isUser'];
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
        ),
        child: Text(
          message['text'],
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isUser ? Colors.white : const Color(0xFF1E293B),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final bool isLimitReached = _messageCount >= _maxMessages;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              isLimitReached ? 'Session Limit Reached' : 'Remaining messages: ${_maxMessages - _messageCount}',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: isLimitReached ? Colors.red : Colors.grey),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isLimitReached ? Colors.grey.shade200 : const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    enabled: !isLimitReached,
                    maxLines: null,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: isLimitReached ? 'Start a new session to chat more' : 'Ask follow-up questions...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: isLimitReached ? null : _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLimitReached ? Colors.grey.shade300 : const Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
