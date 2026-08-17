import 'package:flutter/material.dart';

import 'pages/booking_history_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/my_booking_page.dart';
import 'pages/parking_slots_page.dart';
import 'pages/register_page.dart';
import 'pages/splash_page.dart';
import 'theme/app_theme.dart';

class SmartParkingApp extends StatelessWidget {
  const SmartParkingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Parking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/parking-slots': (context) => const ParkingSlotsPage(),
        '/my-booking': (context) => const MyBookingPage(),
        '/booking-history': (context) => const BookingHistoryPage(),
      },
    );
  }
}
