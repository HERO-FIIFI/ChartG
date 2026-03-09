import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'app_theme.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  static const int _totalPages = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }

  void _goNext() {
    if (_currentPage < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: const [
              _WelcomePage(),
              _FeaturesPage1(),
              _FeaturesPage2(),
              _GetStartedPage(),
            ],
          ),
          // Bottom bar (hidden on last page)
          if (_currentPage < _totalPages - 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                color: AppColors.background,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip
                    TextButton(
                      onPressed: () async {
                        await _markOnboardingComplete();
                        if (mounted) context.go('/login');
                      },
                      child: const Text('Skip', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    // Dots
                    SmoothPageIndicator(
                      controller: _controller,
                      count: _totalPages,
                      effect: const ExpandingDotsEffect(
                        activeDotColor: AppColors.gold,
                        dotColor: AppColors.border,
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3,
                      ),
                    ),
                    // Next
                    GestureDetector(
                      onTap: _goNext,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: AppColors.background),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Page 1: Welcome ────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo / Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: const Icon(Icons.shield_rounded, size: 60, color: AppColors.gold),
          ),
          const SizedBox(height: 40),
          const Text(
            'Chart Guardian',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your Professional\nForex Companion',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.gold,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text(
            'Stay ahead of the markets with real-time news, smart alerts, advanced charting, and a complete trading toolkit.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

// ─── Page 2: Features (News, Charts, Alerts, Journal) ───────────────────────

class _FeaturesPage1 extends StatelessWidget {
  const _FeaturesPage1();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stay Informed\n& Manage Risk',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const GoldDivider(),
          const SizedBox(height: 40),
          _FeatureTile(
            icon: Icons.newspaper_rounded,
            color: AppColors.blue,
            title: 'Live Currency News',
            subtitle: 'ForexFactory news filtered by your favourite currencies with reminder notifications.',
          ),
          const SizedBox(height: 24),
          _FeatureTile(
            icon: Icons.candlestick_chart_rounded,
            color: AppColors.gold,
            title: 'TradingView Charts',
            subtitle: 'Full chart analysis with drawing tools. Save your analysis as images.',
          ),
          const SizedBox(height: 24),
          _FeatureTile(
            icon: Icons.notifications_active_rounded,
            color: AppColors.red,
            title: 'Buy / Sell Limit Alerts',
            subtitle: 'Set price alerts on any pair. Get notified by tone and email when price hits.',
          ),
          const SizedBox(height: 24),
          _FeatureTile(
            icon: Icons.book_rounded,
            color: AppColors.green,
            title: 'Trading Journal',
            subtitle: 'Log every trade, track emotions, and review your performance over time.',
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

// ─── Page 3: Features (Education, Bots, Signals, Clock) ─────────────────────

class _FeaturesPage2 extends StatelessWidget {
  const _FeaturesPage2();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grow & Trade\nSmarter',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const GoldDivider(),
          const SizedBox(height: 40),
          _FeatureTile(
            icon: Icons.school_rounded,
            color: AppColors.gold,
            title: 'Forex Education',
            subtitle: 'Access curated books, video courses, and tutorials from top traders.',
          ),
          const SizedBox(height: 24),
          _FeatureTile(
            icon: Icons.smart_toy_rounded,
            color: AppColors.blue,
            title: 'Trading Bots & Signals',
            subtitle: 'Subscribe to premium bot services and live signal feeds from experts.',
          ),
          const SizedBox(height: 24),
          _FeatureTile(
            icon: Icons.access_time_filled_rounded,
            color: AppColors.green,
            title: 'Market Hours Clock',
            subtitle: 'Floating world clock showing live open/close status for all major sessions.',
          ),
          const SizedBox(height: 24),
          _FeatureTile(
            icon: Icons.storefront_rounded,
            color: AppColors.impactMedium,
            title: 'Forex Store',
            subtitle: 'Your one-stop marketplace for forex products, signals, and services.',
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

// ─── Page 4: Get Started ─────────────────────────────────────────────────────

class _GetStartedPage extends StatelessWidget {
  const _GetStartedPage();

  Future<void> _markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rocket_launch_rounded, size: 50, color: AppColors.gold),
          ),
          const SizedBox(height: 32),
          const Text(
            'Ready to Trade\nwith Confidence?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Join thousands of traders using Chart Guardian to stay informed and execute smarter trades.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () async {
              await _markDone();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Log In'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              await _markDone();
              if (context.mounted) context.go('/signup');
            },
            child: const Text('Create Account'),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () async {
              await _markDone();
              if (context.mounted) context.go('/login');
            },
            child: const Text(
              'Continue as Guest',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widget ───────────────────────────────────────────────────────────

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
