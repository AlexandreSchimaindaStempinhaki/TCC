import 'package:flutter/material.dart';
import 'package:tcc/presentation/widgets/nav_bar.dart';

class MyRoutesView extends StatefulWidget {
  const MyRoutesView({super.key});

  @override
  State<MyRoutesView> createState() => _MyRoutesViewState();
}

class _MyRoutesViewState extends State<MyRoutesView> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Center(
        child: Text(
          'Tela Minhas Rotas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2),
    );
  }
}