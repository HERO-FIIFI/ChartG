import 'package:flutter/material.dart';

import '../app_theme.dart';

// ─── Mock Data ────────────────────────────────────────────────────────────────

class _Product {
  final String id;
  final String category;
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String price;
  final bool isSubscription;
  final String? imagePath; // optional asset image

  const _Product({
    required this.id,
    required this.category,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.price,
    this.isSubscription = false,
    this.imagePath,
  });
}

const _categories = ['All', 'Books', 'Courses', 'Signals', 'Bots', 'Tools'];

const _products = [
  _Product(
    id: '1',
    category: 'Books',
    icon: Icons.menu_book_rounded,
    color: AppColors.gold,
    title: 'Trading in the Zone',
    description: 'Master the Psychology of Trading by Mark Douglas. A must-read for every serious trader.',
    price: '\$19.99',
    imagePath: 'assets/images/fundamentalsbook.png',
  ),
  _Product(
    id: '2',
    category: 'Books',
    icon: Icons.menu_book_rounded,
    color: AppColors.gold,
    title: 'The Disciplined Trader',
    description: 'Developing Winning Attitudes — Mark Douglas. Build the mindset of a consistent trader.',
    price: '\$16.99',
    imagePath: 'assets/images/fundamentalsbook2.png',
  ),
  _Product(
    id: '3',
    category: 'Books',
    icon: Icons.menu_book_rounded,
    color: AppColors.gold,
    title: 'ICT Trading Strategy',
    description: 'Inner Circle Trader concepts: liquidity, market structure, order blocks and FVGs.',
    price: '\$29.99',
    imagePath: 'assets/images/ICT-Trading-Strategy.png',
  ),
  _Product(
    id: '3b',
    category: 'Books',
    icon: Icons.menu_book_rounded,
    color: AppColors.gold,
    title: 'Smart Money Concepts',
    description: 'Advanced SMC guide for institutional order flow, break of structure, and entries.',
    price: '\$24.99',
    imagePath: 'assets/images/smcbook.png',
  ),
  _Product(
    id: '3c',
    category: 'Books',
    icon: Icons.menu_book_rounded,
    color: AppColors.gold,
    title: 'Liquidity Mastery',
    description: 'Understand where liquidity rests, how price hunts stops, and how to trade sweeps.',
    price: '\$22.99',
    imagePath: 'assets/images/liquiditybook.png',
  ),
  _Product(
    id: '4',
    category: 'Courses',
    icon: Icons.play_circle_rounded,
    color: AppColors.blue,
    title: 'Price Action Mastery',
    description: '12-hour video course covering candlestick patterns, support/resistance, and setups.',
    price: '\$97.00',
  ),
  _Product(
    id: '4b',
    category: 'Courses',
    icon: Icons.play_circle_rounded,
    color: AppColors.blue,
    title: 'Forex Fundamentals',
    description: 'Complete beginner-to-advanced forex trading course with live Q&A sessions.',
    price: '\$149.00',
    imagePath: 'assets/images/fundamentals.png',
  ),
  _Product(
    id: '5',
    category: 'Signals',
    icon: Icons.cell_tower_rounded,
    color: AppColors.green,
    title: 'Premium FX Signals',
    description: 'Daily buy/sell signals with entry, SL, and TP for major pairs. 85%+ win rate.',
    price: '\$49/mo',
    isSubscription: true,
  ),
  _Product(
    id: '6',
    category: 'Signals',
    icon: Icons.cell_tower_rounded,
    color: AppColors.green,
    title: 'Gold & Crypto Signals',
    description: 'Specialised signals for XAU/USD and top crypto pairs. Includes market commentary.',
    price: '\$39/mo',
    isSubscription: true,
  ),
  _Product(
    id: '7',
    category: 'Bots',
    icon: Icons.smart_toy_rounded,
    color: Color(0xFF8B5CF6),
    title: 'EA Scalper Pro',
    description: 'MT4/MT5 Expert Advisor for scalping EUR/USD. Average 200+ pips monthly.',
    price: '\$199',
  ),
  _Product(
    id: '8',
    category: 'Bots',
    icon: Icons.smart_toy_rounded,
    color: Color(0xFF8B5CF6),
    title: 'Trend Rider Bot',
    description: 'Trend-following EA optimised for GBP/JPY and USD/CAD on H4 timeframe.',
    price: '\$149',
  ),
  _Product(
    id: '9',
    category: 'Tools',
    icon: Icons.calculate_rounded,
    color: AppColors.impactMedium,
    title: 'Position Size Calculator',
    description: 'Professional risk calculator. Set risk % and account size to get exact lot sizes.',
    price: 'Free',
  ),
  _Product(
    id: '10',
    category: 'Tools',
    icon: Icons.bar_chart_rounded,
    color: AppColors.impactMedium,
    title: 'Trade Journal Pro',
    description: 'Advanced Excel-based trade journal with performance analytics and charts.',
    price: '\$29',
  ),
];

// ─── Store Screen ──────────────────────────────────────────────────────────────

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String _selectedCategory = 'All';
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Product> get _filtered {
    return _products.where((p) {
      final matchCat =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchQuery = _query.isEmpty ||
          p.title.toLowerCase().contains(_query.toLowerCase()) ||
          p.description.toLowerCase().contains(_query.toLowerCase());
      return matchCat && matchQuery;
    }).toList();
  }

  void _showProductDetail(_Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProductDetailSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Category chips
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.gold
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.gold : AppColors.border,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected
                            ? AppColors.background
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Product grid
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('No products found.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _ProductCard(
                      product: _filtered[i],
                      onTap: () => _showProductDetail(_filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Product Card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final _Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  product.imagePath!,
                  height: 70,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: product.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(product.icon,
                        color: product.color, size: 28),
                  ),
                ),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: product.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(product.icon, color: product.color, size: 22),
              ),
            const SizedBox(height: 10),
            Text(
              product.category.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: product.color,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                product.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.description,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.price,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Product Detail Sheet ──────────────────────────────────────────────────────

class _ProductDetailSheet extends StatelessWidget {
  final _Product product;

  const _ProductDetailSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => SingleChildScrollView(
        controller: scrollCtrl,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: product.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(product.icon, color: product.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: product.color,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              product.description,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Price',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Text(
                      product.price,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
                if (product.isSubscription) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Subscription',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.title} — coming soon!'),
                    backgroundColor: AppColors.card,
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_rounded),
              label: Text(
                  product.isSubscription ? 'Subscribe Now' : 'Buy Now'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
