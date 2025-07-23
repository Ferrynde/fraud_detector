
// lib/screens/home_screen.dart
import 'package:fe_detect/utils/app_constant.dart';
import 'package:fe_detect/utils/app_theme.dart';
import 'package:fe_detect/widget/app_logo.dart';
import 'package:flutter/material.dart';
// import '../tabs/home_tab.dart';
// import '../tabs/history_tab.dart';
// import '../tabs/profile_tab.dart';
// import '../utils/app_constants.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        elevation: 0.5,
        title: Row(
          children: [
            AppLogo(size: 24),
            SizedBox(width: 12),
            Text(
              AppConstants.appName,
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: AppTheme.textSecondaryColor),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.account_circle_outlined, color: AppTheme.textSecondaryColor),
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // HomeTab(),
          // HistoryTab(),
          // ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}