import 'package:flutter/material.dart';

import '/backend/supabase/repositories/content_safety_repository.dart';
import '/backend/supabase/repositories/profile_repository.dart';

class ReportContentSheet extends StatefulWidget {
  const ReportContentSheet({
    super.key,
    required this.contentId,
    required this.authorId,
    required this.contentType,
    this.authorUsername = '',
    this.imageUrl = '',
  });

  final String contentId;
  final String authorId;
  final String authorUsername;
  final String imageUrl;
  final ReportedContentType contentType;

  @override
  State<ReportContentSheet> createState() => _ReportContentSheetState();
}

class _ReportContentSheetState extends State<ReportContentSheet> {
  static const _green = Color(0xFF16E57A);
  static const _surface = Color(0xFF141414);
  static const _muted = Color(0xFF9B9B9B);
  static const _reasons = <(IconData, String)>[
    (Icons.thumb_down_alt_outlined, "I don't like it"),
    (Icons.campaign_outlined, 'Spam or unwanted content'),
    (Icons.warning_amber_rounded, 'Nudity or sexual activity'),
    (Icons.record_voice_over_outlined, 'Hate speech or symbols'),
    (Icons.dangerous_outlined, 'Violence or dangerous activity'),
    (Icons.fact_check_outlined, 'False information'),
    (Icons.person_off_outlined, 'Bullying or harassment'),
    (Icons.money_off_rounded, 'Scam or fraud'),
    (Icons.health_and_safety_outlined, 'Self-harm or eating disorders'),
    (Icons.gavel_outlined, 'Illegal or regulated goods'),
    (Icons.copyright_outlined, 'Intellectual property violation'),
    (Icons.more_horiz, 'Something else'),
  ];

  final _details = TextEditingController();
  String? _reason;
  bool _submitting = false;
  bool _blocking = false;
  ContentReportResult? _result;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await ContentSafetyRepository().submitReport(
        contentId: widget.contentId,
        reportedUserId: widget.authorId,
        contentType: widget.contentType,
        reason: _reason!,
        details: _details.text.trim(),
        imageUrl: widget.imageUrl,
      );
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit report: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _block() async {
    if (_blocking) return;
    setState(() => _blocking = true);
    try {
      await ProfileRepository().block(widget.authorId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _blocking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not block account: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .92,
        ),
        padding: EdgeInsets.fromLTRB(20, 10, 20, 18 + bottom),
        decoration: const BoxDecoration(
          color: Color(0xFF090909),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF292929))),
        ),
        child: _result == null ? _buildForm() : _buildSuccess(),
      ),
    );
  }

  Widget _buildForm() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF454545),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Row(
            children: [
              const Expanded(
                child: Text('Report content',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w700)),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Why are you reporting this ${widget.contentType.label}? Your report is private.',
              style: const TextStyle(color: _muted, height: 1.45),
            ),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _reasons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _reasons[index];
                final selected = _reason == item.$2;
                return InkWell(
                  onTap: () => setState(() => _reason = item.$2),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF0E2C1E) : _surface,
                      border: Border.all(
                        color: selected ? _green : const Color(0xFF292929),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(item.$1,
                            color: selected ? _green : Colors.white70,
                            size: 21),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(item.$2,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: selected ? _green : const Color(0xFF565656),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _details,
            minLines: 1,
            maxLines: 3,
            maxLength: 500,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add details (optional)',
              hintStyle: const TextStyle(color: _muted),
              counterStyle: const TextStyle(color: _muted),
              filled: true,
              fillColor: _surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF292929)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF292929)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _green),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _reason == null || _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                disabledBackgroundColor: const Color(0xFF1F4B36),
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text('Submit report',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      );

  Widget _buildSuccess() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
                color: Color(0xFF0E3724), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: _green, size: 42),
          ),
          const SizedBox(height: 20),
          const Text('Report submitted',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            _result!.moderationEmailQueued
                ? 'GymFeed moderation has been notified. Thank you for helping keep the community safe.'
                : 'Your report is safely in the moderation queue. Email delivery was unavailable, but the report was not lost.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _blocking ? null : _block,
              icon: const Icon(Icons.block, color: Color(0xFFFF5A62)),
              label: Text(
                _blocking
                    ? 'Blocking…'
                    : 'Block ${widget.authorUsername.isEmpty ? 'this account' : '@${widget.authorUsername}'}',
                style: const TextStyle(
                    color: Color(0xFFFF5A62), fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF663039)),
                shape: const StadiumBorder(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.black,
                  shape: const StadiumBorder()),
              child: const Text('Done',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      );
}
