import 'package:expensesappflutter/auth/login_page.dart';
import 'package:expensesappflutter/common/colors.dart';
import 'package:expensesappflutter/home_page.dart';
import 'package:expensesappflutter/news_page.dart';
import 'package:expensesappflutter/overview_page.dart';
import 'package:expensesappflutter/pages/account_page.dart';
import 'package:expensesappflutter/pages/categories_page.dart';
import 'package:expensesappflutter/pages/expense_pages/expense_page.dart';
import 'package:expensesappflutter/pages/notifications_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensesappflutter/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainView extends StatefulWidget {
  final String userId;

  const MainView({super.key, required this.userId});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int selectedIndex = 0;
  String name = '';
  String email = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _logout() async {
    try {
      // Remove or delete saved login credentials
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('savedEmail');
      await prefs.remove('savedPassword');
      await prefs.remove('savedUserId');
      await prefs.remove('savedUserEmail');
      await prefs.remove('savedUserName');

      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      final userData = userDoc.data();
      if (userData != null) {
        final userProfile = UserProfile.fromFirestore(userData);

        setState(() {
          name = userProfile.name;
          email = userProfile.email;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Changes the body of the page
  void onItemTapped(int index) {
    if (index < 4) {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBase,
      appBar: AppBar(
        backgroundColor: AppColors.darkBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),

      // Menu Panel
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
        width: MediaQuery.of(context).size.width * 0.75,
        backgroundColor: AppColors.darkBase,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: <Widget>[
            const SizedBox(height: 16),
            // Menu panel header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              color: AppColors.darkBase,
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mediumAccent,
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '',
                        style: const TextStyle(
                          fontSize: 24,
                          color: AppColors.lightAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name and email
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w400,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List of menus/navigations
            ListTile(
              leading: const Icon(
                Icons.home_rounded,
                color: AppColors.primaryText,
              ),
              title: const Text(
                'Home',
                style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w400),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onItemTapped(0);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.bar_chart_outlined,
                color: AppColors.primaryText,
              ),
              title: const Text(
                'Statistics',
                style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w400),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onItemTapped(1);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.newspaper_rounded,
                color: AppColors.primaryText,
              ),
              title: const Text(
                'News',
                style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w400),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onItemTapped(2);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.notifications_rounded,
                color: AppColors.primaryText,
              ),
              title: const Text(
                'Reminders',
                style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w400),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onItemTapped(3);
              },
            ),
            const Divider(
              color: AppColors.secondaryText,
              thickness: 0.5,
              indent: 16,
              endIndent: 16,
              height: 20,
            ),
            ListTile(
              leading: const Icon(
                Icons.widgets_rounded,
                color: AppColors.primaryText,
              ),
              title: const Text(
                'Categories',
                style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w400),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoriesPage(userId: widget.userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.account_box_rounded,
                color: AppColors.primaryText,
              ),
              title: const Text(
                'Account',
                style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w400),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AccountPage(userId: widget.userId)),
                ).then((value) {
                  if (value == true) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainView(
                          userId: widget.userId,
                        ),
                      ),
                    );
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.logout_outlined,
                color: AppColors.primaryText,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w400),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),

      // Body
      body: Stack(
        children: [
          IndexedStack(
            index: selectedIndex,
            children: [
              HomePage(userId: widget.userId),
              OverviewPage(userId: widget.userId),
              const NewsPage(),
              NotificationsPage(userId: widget.userId),
            ],
          ),
        ],
      ),

      // Bottom navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.darkBase,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10.0,
              spreadRadius: 2.0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          color: Colors.transparent,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: SizedBox(
            height: 60.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.home,
                    color: selectedIndex == 0
                        ? AppColors.lightAccent
                        : AppColors.secondaryText,
                  ),
                  onPressed: () => onItemTapped(0),
                ),
                IconButton(
                  icon: Icon(
                    Icons.bar_chart,
                    color: selectedIndex == 1
                        ? AppColors.lightAccent
                        : AppColors.secondaryText,
                  ),
                  onPressed: () => onItemTapped(1),
                ),
                const SizedBox(width: 40.0),
                IconButton(
                  icon: Icon(
                    Icons.newspaper,
                    color: selectedIndex == 2
                        ? AppColors.lightAccent
                        : AppColors.secondaryText,
                  ),
                  onPressed: () => onItemTapped(2),
                ),
                IconButton(
                  icon: Icon(
                    Icons.notifications_rounded,
                    color: selectedIndex == 3
                        ? AppColors.lightAccent
                        : AppColors.secondaryText,
                  ),
                  onPressed: () => onItemTapped(3),
                ),
              ],
            ),
          ),
        ),
      ),

      // Add expense icon
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10.0,
              spreadRadius: 2.0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExpensePage(userId: widget.userId),
              ),
            ).then((value) {
              if (value == true) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MainView(
                      userId: widget.userId,
                    ),
                  ),
                );
              }
            });
          },
          backgroundColor: AppColors.lightAccent,
          shape: const CircleBorder(),
          elevation: 8.0,
          child: const Icon(Icons.add, size: 32.0),
        ),
      ),
    );
  }
}
