import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:solo_app/core/widgets/solo_logo.dart';
import 'package:solo_app/home/notification/alert_history_page.dart';
import 'package:solo_app/home/notification/checkin_history_page.dart';
import 'package:solo_app/home/notification/history_store.dart';
import 'package:solo_app/home/notification/notification_api.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  // ── Palette ──
  static const Color _bg = Color(0xFFF7F8F3);
  static const Color _navy = Color(0xFF002C3E);
  static const Color _label = Color(0xFF5A6C7D);
  static const Color _divider = Color(0x338A99A6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── SOLO logo ──
              const SoloLogo(),
              const SizedBox(height: 28),

              // ── "History" heading ──
              const Text(
                'History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 8),

              // ── Menu items ──
              _historyTile(
                context,
                label: 'View Past Check-ins',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckinHistoryPage()),
                  );
                },
              ),
              const Divider(color: _divider, height: 1, thickness: 1),

              _historyTile(
                context,
                label: 'View Sent Alerts',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AlertHistoryPage()),
                  );
                },
              ),
              const Divider(color: _divider, height: 1, thickness: 1),

              _historyTile(
                context,
                label: 'Clear History',
                onTap: () => _confirmClearHistory(context),
              ),
              const Divider(color: _divider, height: 1, thickness: 1),

              const Spacer(),

              // ── Back arrow ──
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Color(0xFF8A99A6), size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyTile(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: _label,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF8A99A6), size: 22),
          ],
        ),
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon + "Clear History" title in one row ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/svg/dustbin.svg',
                      width: 38,
                      height: 38,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Clear History",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF002C3E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Main warning text ──
                const Text(
                  "Are you sure you want\nto clear your history?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF002C3E),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Sub-caption ──
                const Text(
                  "Your past check-ins and alerts will be\npermanently deleted.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8A99A6),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Buttons ──
                Row(
                  children: [
                    // Cancel — outlined pill
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF002C3E),
                            side: const BorderSide(
                              color: Color(0xFF002C3E),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Confirm — filled navy pill
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF002C3E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await NotificationApi.clearCheckinHistory();
                            await HistoryStore.clearAll();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('History cleared'),
                              ),
                            );
                          },
                          child: const Text(
                            "Confirm",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
        );
      },
    );
  }
}
