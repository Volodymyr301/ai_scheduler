import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VoiceInputScreen extends StatefulWidget {
  const VoiceInputScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Voice Input',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const VoiceInputScreen();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _dot1Animation;
  late Animation<double> _dot2Animation;
  late Animation<double> _dot3Animation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(); // No reverse - just continuous forward loop

    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Continuous sequential jump animations - 1 → 2 → 3 → repeat seamlessly
    // Total cycle is 75% of animation, leaving 25% for seamless loop back to dot 1
    
    // Dot 1: jumps at start (0-25%)
    _dot1Animation = TweenSequence<double>([
      // Jump (0-25%)
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -16.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 12.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -16.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 12.5,
      ),
      // Wait for dots 2 and 3 (25-100%)
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 75.0,
      ),
    ]).animate(_pulseController);

    // Dot 2: jumps after dot 1 (25-50%)
    _dot2Animation = TweenSequence<double>([
      // Wait for dot 1 (0-25%)
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 25.0,
      ),
      // Jump (25-50%)
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -16.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 12.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -16.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 12.5,
      ),
      // Wait for dot 3 (50-100%)
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 50.0,
      ),
    ]).animate(_pulseController);

    // Dot 3: jumps after dot 2 (50-75%)
    _dot3Animation = TweenSequence<double>([
      // Wait for dots 1 and 2 (0-50%)
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 50.0,
      ),
      // Jump (50-75%)
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -16.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 12.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -16.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 12.5,
      ),
      // Stay down until loop (75-100%)
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 25.0,
      ),
    ]).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: const Color(0xFF0F172A).withOpacity(0.85),
          child: Stack(
            children: [
              // Background radial gradient illumination with blur
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.2,
                          colors: [
                            Color(0xFF8B5CF6).withOpacity(0.25 * _glowAnimation.value),
                            Color(0xFF3B82F6).withOpacity(0.15 * _glowAnimation.value),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Close button
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              // Center content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated microphone with glow
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ring effect with gradient
                            Container(
                              width: 160 * _pulseAnimation.value,
                              height: 160 * _pulseAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 2,
                                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                ),
                              ),
                            ),
                            // Main circle with animated dots
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF3B82F6),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.6),
                                    blurRadius: 48,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Dot 1
                                    AnimatedBuilder(
                                      animation: _dot1Animation,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(0, _dot1Animation.value),
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    // Dot 2
                                    AnimatedBuilder(
                                      animation: _dot2Animation,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(0, _dot2Animation.value),
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    // Dot 3
                                    AnimatedBuilder(
                                      animation: _dot3Animation,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(0, _dot3Animation.value),
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                    // Instruction text
                    Container(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          final calculatedOpacity = 0.7 + (0.3 * (_pulseAnimation.value - 0.97) / 0.06);
                          return Opacity(
                            opacity: calculatedOpacity.clamp(0.0, 1.0),
                            child: child,
                          );
                        },
                        child: Text(
                          'Щойно завершите, натисніть на\nмікрофон знову',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

