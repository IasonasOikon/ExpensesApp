import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensesappflutter/common/colors.dart';
import 'package:flutter/material.dart';
import 'package:expensesappflutter/models/category_model.dart';

class CategoriesPage extends StatefulWidget {
  final String userId;

  const CategoriesPage({super.key, required this.userId});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final List<Category> _customCategories = [];

  // Default categories
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Rent', 'icon': Icons.house_rounded},
    {'name': 'Internet', 'icon': Icons.router_rounded},
    {'name': 'Utilities', 'icon': Icons.dynamic_form_rounded},
    {'name': 'Transportation', 'icon': Icons.directions_car_rounded},
    {'name': 'Groceries', 'icon': Icons.local_grocery_store_rounded},
    {'name': 'Food', 'icon': Icons.fastfood_rounded},
    {'name': 'Shopping', 'icon': Icons.shopping_cart_rounded},
    {'name': 'Repairs', 'icon': Icons.build_rounded},
    {'name': 'Healthcare', 'icon': Icons.local_hospital_rounded},
    {'name': 'Debt Payments', 'icon': Icons.credit_card_rounded},
    {'name': 'Entertainment', 'icon': Icons.movie_rounded},
    {'name': 'Education', 'icon': Icons.school_rounded},
    {'name': 'Travel', 'icon': Icons.flight_rounded},
    {'name': 'Gifts', 'icon': Icons.redeem_rounded},
    {'name': 'Subscriptions', 'icon': Icons.subscriptions_rounded},
    {'name': 'Insurance', 'icon': Icons.money_rounded},
    {'name': 'Pets', 'icon': Icons.pets_rounded},
    {'name': 'Childcare', 'icon': Icons.child_care_rounded},
    {'name': 'Savings', 'icon': Icons.savings_rounded},
    {'name': 'Miscellaneous', 'icon': Icons.category_rounded},
  ];

  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategoriesFromFirebase();
  }

  void _loadCategoriesFromFirebase() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('categories')
        .get();

    setState(() {
      _customCategories.clear();
      for (var doc in snapshot.docs) {
        _customCategories.add(Category.fromMap(doc.data()));
      }
    });
  }

  void _addCategory() async {
    if (_categoryController.text.isNotEmpty) {
      final newCategory = Category(catName: _categoryController.text);

      // Save category to Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('categories')
          .add(newCategory.toMap());

      // Add to the local list
      setState(() {
        _customCategories.add(newCategory);
      });
      _categoryController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBase,
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(color: AppColors.primaryText),
        ),
        centerTitle: true,
        backgroundColor: AppColors.darkBase,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(
          color: AppColors.primaryText,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      hintText: 'Add custom category',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                      ),
                      filled: true,
                      fillColor: AppColors.darkBase,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide:
                            const BorderSide(color: AppColors.secondaryText),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide:
                            const BorderSide(color: AppColors.secondaryText),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide:
                            const BorderSide(color: AppColors.mediumAccent),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12.0),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.mediumAccent,
                    child: IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: AppColors.lightAccent,
                      ),
                      onPressed: _addCategory,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Custom Categories',
              style: TextStyle(
                  fontSize: 16.0,
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            _buildCustomCategoryGrid(_customCategories),
            const SizedBox(height: 20),
            const Text(
              'Categories',
              style: TextStyle(
                  fontSize: 16.0,
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            _buildExistingCategoryGrid(_categories),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCategoryGrid(List<Category> categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Number of column or icon per row
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return _buildCustomCategoryItem(categories[index]);
      },
    );
  }

  Widget _buildExistingCategoryGrid(List<Map<String, dynamic>> categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Number of column or icon per row
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return _buildExistingCategoryItem(categories[index]);
      },
    );
  }

  Widget _buildCustomCategoryItem(Category category) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.mediumAccent,
          child: Icon(
            Icons.widgets_rounded,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(category.catName,
            style: const TextStyle(fontSize: 12, color: AppColors.primaryText)),
      ],
    );
  }

  Widget _buildExistingCategoryItem(Map<String, dynamic> category) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.mediumAccent,
          child: Icon(category['icon'], color: AppColors.secondaryText),
        ),
        const SizedBox(height: 5),
        Text(category['name'],
            style: const TextStyle(fontSize: 12, color: AppColors.primaryText)),
      ],
    );
  }
}
