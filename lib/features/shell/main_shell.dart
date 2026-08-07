import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../assistant/assistant_screen.dart';
import '../home/home_screen.dart';
import '../menu/menu_screen.dart';
import '../opportunities/pipeline_screen.dart';
import '../tasks/tasks_screen.dart';
import 'create_sheet.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _titles = ['Home', 'Pipeline', 'Tasks', 'RYSE AI', 'Menu'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          PipelineScreen(),
          TasksScreen(),
          AssistantScreen(),
          MenuScreen(),
        ],
      ),
      floatingActionButton: _index <= 2
          ? FloatingActionButton(
              tooltip: 'Create new record',
              onPressed: () => showCreateSheet(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.filter_alt_outlined),
              activeIcon: Icon(Icons.filter_alt),
              label: 'Pipeline',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              activeIcon: Icon(Icons.task_alt),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: AppColors.aiGradient,
                ).createShader(bounds),
                child:
                    const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              label: _titles[3],
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              label: 'Menu',
            ),
          ],
        ),
      ),
    );
  }
}
