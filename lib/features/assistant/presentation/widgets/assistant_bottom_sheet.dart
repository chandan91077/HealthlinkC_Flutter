import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:healthlink_connect_flutter/features/assistant/data/models/assistant_message.dart';
import 'package:healthlink_connect_flutter/features/assistant/presentation/providers/assistant_provider.dart';

// ─── Public FAB entry ─────────────────────────────────────────────────────────

class MediAIFab extends StatelessWidget {
  const MediAIFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'mediAI_fab',
      backgroundColor: const Color(0xFF0D9488),
      onPressed: () => _openAssistant(context),
      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
    );
  }

  void _openAssistant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AssistantProvider>(),
        child: const _AssistantBottomSheet(),
      ),
    );
  }
}

// ─── Bottom Sheet ─────────────────────────────────────────────────────────────

class _AssistantBottomSheet extends StatefulWidget {
  const _AssistantBottomSheet();

  @override
  State<_AssistantBottomSheet> createState() => _AssistantBottomSheetState();
}

class _AssistantBottomSheetState extends State<_AssistantBottomSheet> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();

  static const _darkBg = Color(0xFF0A0F1E);
  static const _teal = Color(0xFF2DD4BF);
  static const _border = Color(0x1AFFFFFF);

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    context.read<AssistantProvider>().submitText(text);
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null || !mounted) return;
    await context.read<AssistantProvider>().analyzeReport(File(picked.path));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.78,
      decoration: BoxDecoration(
        color: _darkBg.withOpacity(0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 32,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMessages()),
          _buildVoiceWave(),
          _buildInput(),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Consumer<AssistantProvider>(
      builder: (_, provider, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _border)),
          gradient: LinearGradient(
            colors: [
              _teal.withOpacity(0.08),
              const Color(0xFF06B6D4).withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            // AI Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2DD4BF), Color(0xFF06B6D4)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _teal.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.medical_services_rounded,
                  size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('MediAI',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      const SizedBox(width: 4),
                      Icon(Icons.auto_awesome_rounded, size: 12, color: _teal),
                    ],
                  ),
                  Text(
                    provider.isListening
                        ? '🎤 Listening...'
                        : provider.isThinking
                            ? '⏳ Thinking...'
                            : 'Your Healthcare Assistant',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 10),
                  ),
                ],
              ),
            ),
            // TTS toggle
            _IconBtn(
              icon: provider.isTtsEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              onTap: provider.toggleTts,
              color: provider.isTtsEnabled ? _teal : null,
            ),
            // Clear
            _IconBtn(
              icon: Icons.delete_outline_rounded,
              onTap: provider.clearMessages,
              color: Colors.red.withOpacity(0.7),
            ),
            // Close
            _IconBtn(
              icon: Icons.close_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Message List ──────────────────────────────────────────────────────────

  Widget _buildMessages() {
    return Consumer<AssistantProvider>(
      builder: (_, provider, __) {
        final msgs = provider.messages;
        if (msgs.isEmpty) return const _EmptyState();
        return ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: msgs.length,
          itemBuilder: (_, i) => _MessageBubble(message: msgs[i]),
        );
      },
    );
  }

  // ─── Voice Interim ─────────────────────────────────────────────────────────

  Widget _buildVoiceWave() {
    return Consumer<AssistantProvider>(
      builder: (_, provider, __) {
        if (!provider.isListening && provider.interimText.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.05),
            border: Border(top: BorderSide(color: _teal.withOpacity(0.2))),
          ),
          child: Row(
            children: [
              _PulsingDot(color: _teal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  provider.interimText.isEmpty
                      ? 'Listening for your voice...'
                      : provider.interimText,
                  style: TextStyle(
                      color: _teal.withOpacity(0.85),
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Input Bar ─────────────────────────────────────────────────────────────

  Widget _buildInput() {
    return Consumer<AssistantProvider>(
      builder: (_, provider, __) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            top: 8,
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    // Mic Button
                    _InputIconBtn(
                      icon: provider.isListening
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      color: provider.isListening
                          ? Colors.red.withOpacity(0.8)
                          : Colors.white38,
                      onTap: provider.toggleVoiceInput,
                    ),
                    // Image Upload Button
                    _InputIconBtn(
                      icon: Icons.image_outlined,
                      color: Colors.white38,
                      onTap: _pickImage,
                      tooltip: 'Upload medical report',
                    ),
                    // Text Field
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: provider.isListening
                              ? 'Listening...'
                              : 'Ask MediAI anything...',
                          hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 13),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        enabled: !provider.isListening,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    // Send Button
                    GestureDetector(
                      onTap: provider.isThinking ? null : _send,
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: provider.isThinking
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF2DD4BF),
                                    Color(0xFF06B6D4),
                                  ],
                                ),
                          color:
                              provider.isThinking ? Colors.white12 : null,
                          boxShadow: provider.isThinking
                              ? null
                              : [
                                  BoxShadow(
                                    color: _teal.withOpacity(0.35),
                                    blurRadius: 8,
                                  ),
                                ],
                        ),
                        child: const Icon(Icons.send_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'MediAI never auto-pays · never confirms without your approval',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.18), fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final AssistantMessage message;

  static const _teal = Color(0xFF2DD4BF);

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFF2DD4BF), Color(0xFF06B6D4)]),
              ),
              child: const Icon(Icons.medical_services_rounded,
                  size: 14, color: Colors.white),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF2DD4BF), Color(0xFF06B6D4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: isUser
                    ? [BoxShadow(color: _teal.withOpacity(0.25), blurRadius: 8)]
                    : null,
              ),
              child: message.isLoading
                  ? SizedBox(
                      width: 40,
                      child: Row(
                        children: List.generate(
                          3,
                          (i) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _BouncingDot(delay: i * 200),
                          ),
                        ),
                      ),
                    )
                  : Text(
                      message.content,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : Colors.white.withOpacity(0.9),
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medical_services_rounded,
              size: 48, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 12),
          Text('Ask me anything health-related',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3), fontSize: 13)),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color ?? Colors.white38),
      ),
    );
  }
}

class _InputIconBtn extends StatelessWidget {
  const _InputIconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
          ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(_anim.value),
          ),
        ),
      );
}

class _BouncingDot extends StatefulWidget {
  const _BouncingDot({required this.delay});
  final int delay;

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.0, end: -6.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _anim.value),
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2DD4BF),
            ),
          ),
        ),
      );
}
