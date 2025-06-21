import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';
import 'model.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final Profile otherUser;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

void _showCustomSnackbar(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Text(
      message,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    duration: const Duration(seconds: 1),
    backgroundColor: Colors.teal[700],
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

class _ChatPageState extends State<ChatPage> {
  final myUserId = supabase.auth.currentUser!.id;
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  StreamSubscription<List<Map<String, dynamic>>>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _listenToNewMessages();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  /// Fetching old messages when entering in the chat again
  Future<void> _fetchMessages() async {
    final response = await supabase
        .from('messages')
        .select()
        .eq('conversation_id', widget.conversationId)
        .neq('deleted', true)
        .order('created_at', ascending: true);

    if (mounted) {
      setState(() {
        _messages = response.map((data) => Message.fromMap(data)).toList();
      });

      _markMessagesAsSeen();
      _scrollToBottom();
    }
  }

  /// Listening for new messages in real-time
  ///
  void _listenToNewMessages() {
    _messageSubscription = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('created_at', ascending: true)
        .listen(
          (List<Map<String, dynamic>> data) { // ✅ Ensure correct type
        if (!mounted) return;

        final newMessages = data
            .map((map) => Message.fromMap(map))
            .where((msg) => !msg.deleted)
            .toList();

        setState(() {
          _messages = newMessages;
        });

        _markMessagesAsSeen();
        _scrollToBottom();
      },
      onError: (error) {
        print("🔥 Error in real-time subscription: $error");
      },
    );
  }

  /// Send a new message
  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    final newMessage = {
      'profile_id': myUserId,
      'content': text,
      'conversation_id': widget.conversationId,
      'is_read': false,
      'deleted': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    await supabase.from('messages').insert(newMessage);
  }

  /// Mark messages as seen
  Future<void> _markMessagesAsSeen() async {
    final unseenMessages = _messages.where((msg) => msg.profileId != myUserId && !msg.isRead).toList();

    if (unseenMessages.isNotEmpty) {
      final messageIds = unseenMessages.map((msg) => msg.id).toList();
      for (String messageId in messageIds) {
        await supabase
            .from('messages')
            .update({'is_read': true})
            .eq('id', messageId);
      }
    }
  }

  /// Edit a message
  Future<void> _editMessage(String messageId, String newText) async {
    await supabase.from('messages').update({'content': newText}).eq('id', messageId);

    setState(() {
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(content: newText);
      }
    });
  }

  /// Delete a message
  Future<void> _deleteMessage(String messageId) async {
    await supabase.from('messages').update({'deleted': true}).eq('id', messageId);

    setState(() {
      _messages.removeWhere((msg) => msg.id == messageId);
    });
  }

  /// Scroll to the bottom
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
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
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // IN circular avatar we will show the first letter of the user name
            CircleAvatar(
              backgroundColor: Colors.teal[400], // A nice shade matching WhatsApp
              child: Text(
                widget.otherUser.username.isNotEmpty
                    ? widget.otherUser.username[0].toUpperCase()
                    : '?', // Fallback in case of empty username
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Username and Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.username,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                  ),
                ),
                Text( "Last seen recently",
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () {
              _showCustomSnackbar(context, "Video call feature is not available yet.");
            },
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () {
              _showCustomSnackbar(context, "Audio call feature is not available yet.");
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rounded corners
            onSelected: (value) {
              if (value == 'Profile') {
                _showCustomSnackbar(context, "Opening profile...");
              } else if (value == 'Mute') {
                _showCustomSnackbar(context, "Muted notifications.");
              } else if (value == 'Search') {
                _showCustomSnackbar(context, "Search feature coming soon!");
              } else if (value == 'ClearChat') {
                _showCustomSnackbar(context, "Chat cleared (not implemented).");
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'Profile',
                child: ListTile(
                  leading: Icon(Icons.person, color: Colors.teal[700]),
                  title: Text('View Profile'),
                ),
              ),
              PopupMenuItem(
                value: 'Mute',
                child: ListTile(
                  leading: Icon(Icons.volume_off, color: Colors.redAccent),
                  title: Text('Mute Notifications'),
                ),
              ),
              const PopupMenuDivider(), //separater

              PopupMenuItem(
                value: 'Search',
                child: ListTile(
                  leading: Icon(Icons.search, color: Colors.blue),
                  title: Text('Search in Chat'),
                ),
              ),
              PopupMenuItem(
                value: 'ClearChat',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.grey),
                  title: Text('Clear Chat'),
                ),
              ),
            ],
          )

        ],
      ),

        body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('No messages yet, start the conversation!'))
                : ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(
                  message: message,
                  isMine: message.profileId == myUserId,
                  onEdit: (newText) => _editMessage(message.id, newText),
                  onDelete: () => _deleteMessage(message.id),
                );
              },
            ),
          ),
          _MessageBar(onSend: _sendMessage),
        ],
      ),
    );
  }
}
class _MessageBar extends StatefulWidget {
  final Function(String) onSend;

  const _MessageBar({Key? key, required this.onSend}) : super(key: key);

  @override
  State<_MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<_MessageBar> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[200],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      border: InputBorder.none,
                    ),
                    textInputAction: TextInputAction.send,
                    onChanged: (value) {
                      setState(() {}); // Update UI when typing
                    },
                    onFieldSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        widget.onSend(value.trim());
                        _textController.clear();
                        setState(() {}); // Refresh UI
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // New Stylish Send Button
              InkWell(
                onTap: () {
                  final text = _textController.text.trim();
                  if (text.isNotEmpty) {
                    widget.onSend(text);
                    _textController.clear();
                    setState(() {}); // Refresh UI
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _textController.text.trim().isNotEmpty
                        ? Colors.blue
                        : Colors.grey, // Disabled if no text
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chat bubble widget with edit & delete options
class _ChatBubble extends StatefulWidget {
  final Message message;
  final bool isMine;
  final Function(String) onEdit;
  final VoidCallback onDelete;

  const _ChatBubble({
    Key? key,
    required this.message,
    required this.isMine,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  void _showEditDialog() {
    final TextEditingController _controller = TextEditingController(text: widget.message.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Message"),
        content: TextField(controller: _controller),
        actions: [
          TextButton(
            onPressed: () {
              widget.onEdit(_controller.text); // Update message
              Navigator.pop(context); // Close dialog
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.isMine ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(widget.message.content, style: TextStyle(color: widget.isMine ? Colors.white : Colors.black)),
                ),

                // Show 3-dot menu only on my messages
                if (widget.isMine)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'Edit') _showEditDialog();
                      if (value == 'Delete') widget.onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'Edit', child: Text('Edit')),
                      PopupMenuItem(value: 'Delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),

            // Show "Seen" status only for my messages
            if (widget.isMine)
              Text(widget.message.isRead ? "Seen" : "Unseen", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

}
