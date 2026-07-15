import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _items = [
    (
      icon: '🍔',
      title: 'Your cravings, delivered',
      body:
          'Order your favourite burgers, sides and drinks directly from Burger House.',
    ),
    (
      icon: '👨‍🍳',
      title: 'Made fresh for you',
      body:
          'Our kitchen receives your order instantly and prepares it fresh with care.',
    ),
    (
      icon: '🛵',
      title: 'Fast to your doorstep',
      body:
          'Track your Burger House rider as your hot meal makes its way to you.',
    ),
  ];

  void _next() {
    if (_page == _items.length - 1) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.login),
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _items.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (_, index) {
                    final item = _items[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 230,
                          height: 230,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE5CE),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            item.icon,
                            style: const TextStyle(fontSize: 105),
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _items.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: index == _page ? 28 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == _page
                          ? AppColors.orange
                          : const Color(0xFFD9CEC5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _next,
                child: Text(
                  _page == _items.length - 1 ? 'Get started' : 'Continue',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
