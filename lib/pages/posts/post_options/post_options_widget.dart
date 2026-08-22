import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/components/report_status/report_status_widget.dart';

class PostOptionsWidget extends StatelessWidget {
  const PostOptionsWidget({super.key, this.post});

  final PostsRecord? post;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0xFF292929))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF454545),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              ListTile(
                onTap: post == null ? null : () => _openReport(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                tileColor: const Color(0xFF171717),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                      color: Color(0xFF35191E), shape: BoxShape.circle),
                  child:
                      const Icon(Icons.outlined_flag, color: Color(0xFFFF5A62)),
                ),
                title: Text(
                  post?.foodPost == true ? 'Report food post' : 'Report post',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Tell GymFeed moderation what happened',
                    style: TextStyle(color: Color(0xFF8B8B8B), fontSize: 12)),
                trailing:
                    const Icon(Icons.chevron_right, color: Color(0xFF8B8B8B)),
              ),
            ],
          ),
        ),
      );

  Future<void> _openReport(BuildContext context) async {
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await showModalBottomSheet<bool>(
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      context: rootContext,
      builder: (context) => ReportStatusWidget(
        postReference: post!.reference,
      ),
    );
  }
}
