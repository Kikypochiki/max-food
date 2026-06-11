import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF7EA), Color(0xFFFDFEF9)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFDCECDC)),
                    ),
                    child: const Text(
                      'Fresh local produce',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF257533),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.86),
                              borderRadius: BorderRadius.circular(36),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF29A300,
                                  ).withValues(alpha: 0.14),
                                  blurRadius: 30,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo_ubayharvest.png',
                              height: 200,
                              width: 200,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'UbayHarvest',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              color: Color(0xFF14381F),
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Fresh produce marketplace built for farmers and buyers.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Color(0xFF4C6654),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              _FeatureChip(label: 'Fast ordering'),
                              SizedBox(width: 10),
                              _FeatureChip(label: 'Fresh listings'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F8C32),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () => context.go('/sign-up'),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF163A22),
                        side: const BorderSide(color: Color(0xFFD0E3D3)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.82),
                      ),
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCECDC)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF3C5B44),
        ),
      ),
    );
  }
}
