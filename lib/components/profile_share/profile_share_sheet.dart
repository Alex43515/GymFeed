import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_bar_code/qr/qr.dart';

import '/backend/share_links.dart';

Future<void> showProfileShareSheet(
  BuildContext context, {
  required String username,
  required String displayName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProfileShareSheet(
      username: username,
      displayName: displayName,
    ),
  );
}

/// QR code and link for a profile. Scanning the code with a phone camera opens
/// the profile in GymFeed, or the store page when the app is not installed.
class ProfileShareSheet extends StatefulWidget {
  const ProfileShareSheet({
    super.key,
    required this.username,
    required this.displayName,
  });

  final String username;
  final String displayName;

  @override
  State<ProfileShareSheet> createState() => _ProfileShareSheetState();
}

class _ProfileShareSheetState extends State<ProfileShareSheet> {
  static const _green = Color(0xFF16E77D);
  static const _qrSize = 216.0;

  bool _copied = false;

  String get _url => gymFeedProfileShareUrl(widget.username);

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _url));
    if (mounted) setState(() => _copied = true);
  }

  Future<void> _share(BuildContext buttonContext) async {
    try {
      await shareGymFeedProfile(
        username: widget.username,
        displayName: widget.displayName,
        sharePositionOrigin: shareSheetOrigin(buttonContext),
      );
    } catch (_) {
      await _copy();
    }
  }

  TextStyle _text(double size, Color color, [FontWeight? weight]) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: size,
        color: color,
        fontWeight: weight,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Share your profile',
                  style: _text(18, Colors.white, FontWeight.w700)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: SizedBox(
                  width: _qrSize,
                  height: _qrSize,
                  child: QRCode(
                    key: const ValueKey('profile-qr-code'),
                    data: _url,
                    size: _qrSize,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QRErrorCorrectLevel.M,
                    eyeStyle: const QREyeStyle(
                      color: Colors.black,
                      eyeShape: QREyeShape.square,
                    ),
                    dataModuleStyle: const QRDataModuleStyle(
                      color: Colors.black,
                      dataModuleShape: QRDataModuleShape.square,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('@${widget.username}',
                  style: _text(16, Colors.white, FontWeight.w600)),
              const SizedBox(height: 3),
              Text(
                'Scan with any phone camera to open this profile.',
                textAlign: TextAlign.center,
                style: _text(13, const Color(0xFF9A9A9A)),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('profile-copy-link'),
                      onPressed: _copy,
                      icon: Icon(
                        _copied ? Icons.check_rounded : Icons.link_rounded,
                        size: 18,
                      ),
                      label: Text(_copied ? 'Copied' : 'Copy link'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF3A3A3A)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Builder(
                      builder: (buttonContext) => FilledButton.icon(
                        key: const ValueKey('profile-share-link'),
                        onPressed: () => _share(buttonContext),
                        icon: const Icon(Icons.ios_share_rounded, size: 18),
                        label: const Text('Share link'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
