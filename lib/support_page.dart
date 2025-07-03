import 'package:flutter/material.dart';
import 'package:idris_academy/models/chat_message_model.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:provider/provider.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSendButton = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _showSendButton) setState(() => _showSendButton = hasText);
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;

    final userService = Provider.of<UserService>(context, listen: false);
    userService.sendSupportMessage(_textController.text.trim());
    _textController.clear();

    // Scroll to the bottom after sending a message
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                // Add a confirmation dialog for a better user experience
                _showResetConfirmationDialog(context);
              },
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Reset Chat'),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Consumer<UserService>(
            builder: (context, userService, child) {
              final messages = userService.getSupportChatHistory();
              // Scroll to bottom when new messages arrive
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                }
              });
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildChatMessageBubble(context, message);
                },
              );
            },
          ),
        ),
        _buildMessageInputField(),
      ],
    );
  }

  Widget _buildChatMessageBubble(BuildContext context, ChatMessageModel message) {
    final isUser = message.isSentByUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              // ignore: deprecated_member_use
              icon: Icon(Icons.attach_file_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              onPressed: () {
                // Placeholder for file attachment logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File attachment coming soon!')),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: Icon(_showSendButton ? Icons.send : Icons.mic, color: Theme.of(context).colorScheme.primary),
              onPressed: _showSendButton
                  ? _sendMessage
                  : () {
                      // Placeholder for voice recording logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Voice input coming soon!')),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Reset Chat?'),
              content: const Text('Are you sure you want to clear this conversation? This cannot be undone.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                TextButton(
                    onPressed: () {
                      Provider.of<UserService>(context, listen: false).resetSupportChat();
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Reset')),
              ],
            ));
  }
}