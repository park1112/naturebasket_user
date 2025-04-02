import 'package:flutter/material.dart';
import '../config/theme.dart';

class CustomLoading extends StatefulWidget {
  final double size;
  final Color color;

  const CustomLoading({
    super.key,
    this.size = 50.0,
    this.color = AppTheme.primaryColor,
  });

  @override
  State<CustomLoading> createState() => _CustomLoadingState();
}

class _CustomLoadingState extends State<CustomLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _animation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.9, curve: Curves.easeInOut),
      ),
    );

    _animation3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                _buildAnimatedCircle(_animation1.value, 1.0),
                _buildAnimatedCircle(_animation2.value, 0.85),
                _buildAnimatedCircle(_animation3.value, 0.7),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedCircle(double animationValue, double sizeFactor) {
    return Opacity(
      opacity: (1.0 - (animationValue - 0.5).abs() * 2).clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.5 + animationValue * 0.5,
        child: Container(
          width: widget.size * sizeFactor,
          height: widget.size * sizeFactor,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.3),
            border: Border.all(
              color: widget.color,
              width: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}

// 로딩 오버레이
class LoadingOverlay {
  static OverlayEntry? _overlayEntry;

  // 로딩 표시
  static void show(BuildContext context) {
    if (_overlayEntry != null) {
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.5),
        child: const Center(
          child: CustomLoading(),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // 로딩 숨기기
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
