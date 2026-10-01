import 'dart:async';
import 'package:flutter/material.dart';

class SoloToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
      BuildContext context,
      String message, {
        bool isDark = false,
        Duration duration = const Duration(milliseconds: 3500),
      }) {
    cancel();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastAnimationWidget(
        message: message,
        isDark: isDark,
        duration: duration,
        onDismissed: () {
          if (_currentEntry == entry) {
            if (entry.mounted) {
              entry.remove();
            }
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void cancel() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentEntry != null) {
      if (_currentEntry!.mounted) {
        _currentEntry!.remove();
      }
      _currentEntry = null;
    }
  }
}

class _ToastAnimationWidget extends StatefulWidget {
  final String message;
  final bool isDark;
  final Duration duration;
  final VoidCallback onDismissed;

  const _ToastAnimationWidget({
    required this.message,
    required this.isDark,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_ToastAnimationWidget> createState() => _ToastAnimationWidgetState();
}

class _ToastAnimationWidgetState extends State<_ToastAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 0.3s ease-out as per specification
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // Niche se upar slide hone ke liye
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _controller.forward();

    _timer = Timer(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            widget.onDismissed();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
    widget.isDark ? const Color(0xFF0CB4AB) : const Color(0xFF002C3E);

    // SafeArea ke bottom padding ko include karte hain taaki navigation bar ke upar bilkul chipka rahe
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 0, // Screen ke ekdum bottom par fix
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                bottomPadding > 0 ? bottomPadding + 12 : 20, // Bottom padding safe adjustment
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28), // Sirf upar ke corners rounded
                ),
              ),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFFF5F5F5),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}