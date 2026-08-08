import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:solo_app/core/utils/app_size.dart';
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
  static const Color _divider = Color(0xFF8A99A6);

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
                  color: Color(0xFF002C3E),
                ),
              ),
             // const SizedBox(height: 12),

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
                child: const Icon(Icons.arrow_back, color: _label, size: 24),
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
                fontSize: 14,
                color: _label,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Icon(Icons.chevron_right, color: _label, size: 25),
          ],
        ),
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    AppSize.init(context);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          insetPadding: EdgeInsets.zero, // allows perfect exact sizing
          child: SizedBox(
            width: AppSize.w(335),
            height: AppSize.h(295),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.w(20),
                vertical: AppSize.h(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Icon + "Clear History" title in one row ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          //color: Color(0xFFB5D43C),
                         // shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/svg/dustbin.svg',
                            width: 50,
                            height: 50,
                            // colorFilter: const ColorFilter.mode(
                            //   Color(0xFF002C3E),
                            //   BlendMode.srcIn,
                            // ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Clear History",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF002C3E),
                        ),
                      ),
                    ],
                  ),

                  // ── Main warning text ──
                  const Text(
                    "Are you sure you want to clear\nyour history?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1B3A4B),
                      height: 1.3,
                    ),
                  ),

                  // ── Sub-caption ──
                  const Text(
                    "Your past check-ins and alerts will be\npermanently deleted.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF002C3E),
                      height: 1.4,
                    ),
                  ),

                  // ── Buttons ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cancel — outlined
                      SizedBox(
                        width: AppSize.w(111),
                        height: AppSize.h(46),
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
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSize.w(12)),

                      // Confirm — filled navy
                      SizedBox(
                        width: AppSize.w(111),
                        height: AppSize.h(46),
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
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
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
      },
    );
  }
}
