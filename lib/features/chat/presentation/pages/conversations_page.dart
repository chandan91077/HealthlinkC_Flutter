import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  Timer? _autoRefreshTimer;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _conversations = const [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted || _isLoading) {
        return;
      }
      _loadConversations();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await sl<ApiClient>().get('/api/messages/conversations');
      final data = response.data;
      final conversations = data is List
          ? data
              .whereType<Map>()
              .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _conversations = conversations;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load conversations.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _subtitle(Map<String, dynamic> conversation) {
    final lastMessage = conversation['lastMessage'];
    if (lastMessage is Map<String, dynamic>) {
      final content = lastMessage['content']?.toString() ?? '';
      if (content.isNotEmpty) {
        return content;
      }
    }
    return 'Start chatting';
  }

  String _timeLabel(Map<String, dynamic> conversation) {
    final lastMessage = conversation['lastMessage'];
    if (lastMessage is Map<String, dynamic>) {
      final raw = lastMessage['createdAt']?.toString() ?? '';
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        return DateFormat('hh:mm a').format(dt.toLocal());
      }
    }
    return '';
  }

  String _appointmentId(Map<String, dynamic> conversation) {
    final raw = conversation['appointment_id'];
    if (raw is String) {
      return raw;
    }
    if (raw is Map<String, dynamic>) {
      return raw['_id']?.toString() ?? '';
    }
    if (raw is Map) {
      return raw['_id']?.toString() ?? '';
    }
    return raw?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: _conversations.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('No conversations yet.')),
                          ],
                        )
                      : ListView.separated(
                          itemCount: _conversations.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final conversation = _conversations[index];
                            final appointmentId = _appointmentId(conversation);
                            final unread = (conversation['unreadCount'] as num?)
                                    ?.toInt() ??
                                0;

                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(
                                conversation['otherPartyName']?.toString() ??
                                    'Conversation',
                              ),
                              subtitle: Text(
                                _subtitle(conversation),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _timeLabel(conversation),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  if (unread > 0)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        unread.toString(),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                ],
                              ),
                              onTap: appointmentId.isEmpty
                                  ? null
                                  : () => context.push('/chat/$appointmentId'),
                            );
                          },
                        ),
                ),
    );
  }
}
