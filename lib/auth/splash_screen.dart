import 'dart:math';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class SplashAnimationScreen extends StatefulWidget {
  const SplashAnimationScreen({super.key});

  @override
  State<SplashAnimationScreen> createState() => _SplashAnimationScreenState();
}

class _SplashAnimationScreenState extends State<SplashAnimationScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> cardsInAnim;
  late Animation<double> centerCardAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    cardsInAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    centerCardAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.0, curve: Curves.easeInOut),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2800), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ================= CORNER LOGOS =================
  Widget cornerCard(Alignment start, double rot) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        // 🔥 Fade out when center logo starts
        double opacity = 1.0;
        if (_controller.value > 0.6) {
          opacity = (0.75 - _controller.value).clamp(0.0, 1.0);
        }

        return Opacity(
          opacity: opacity,
          child: Align(
            alignment:
                Alignment.lerp(start, Alignment.center, cardsInAnim.value)!,
            child: Transform.rotate(
              angle: rot * (1 - cardsInAnim.value),
              child: _logo(180),
            ),
          ),
        );
      },
    );
  }

  /// ================= CENTER LOGO =================
  Widget centerCard() {
    return AnimatedBuilder(
      animation: centerCardAnim,
      builder: (_, __) {
        if (_controller.value < 0.65) {
          return const SizedBox();
        }

        return Transform.scale(
          scale: 0.9 + (0.3 * centerCardAnim.value),
          child: _logo(260),
        );
      },
    );
  }

  Widget _logo(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset('assets/images/Logo_2.png', fit: BoxFit.contain),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          /// 👇 Corner logos (fade out automatically)
          cornerCard(Alignment.topLeft, -pi / 4),
          cornerCard(Alignment.topRight, pi / 4),
          cornerCard(Alignment.bottomLeft, pi / 6),
          cornerCard(Alignment.bottomRight, -pi / 6),

          /// 👇 Center logo (comes after corners hide)
          centerCard(),
        ],
      ),
    );
  }
}
