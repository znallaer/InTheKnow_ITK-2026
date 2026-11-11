import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget {
  final String? message;

  final Duration duration;

  const LoadingPage({
    super.key,
    this.message,
    this.duration = const Duration(milliseconds: 2000),
  });

  static const Color _dark = Color(0xFF23282D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Image.asset(
                'assets/images/itk_logo.png',
                width: 180,
                errorBuilder: (_, _, _) => const Column(
                  children: [
                    Icon(Icons.lightbulb, size: 72, color: Color(0xFFFAB800)),
                    Text(
                      'iTK',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: _dark,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'IN-THE-KNOW',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: _dark,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 110),


              Container(
                width: 190,
                height: 26,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _dark, width: 2.5),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.08, end: 1.0),
                  duration: duration,
                  curve: Curves.easeInOut,
                  builder: (context, value, _) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _dark,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}