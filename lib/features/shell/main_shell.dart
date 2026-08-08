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
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              onPressed: () => showCreateSheet(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.header,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Pipeline',
            ),
            const NavigationDestination(
              icon: Icon(Icons.check_circle_outline),
              selectedIcon: Icon(Icons.task_alt),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: _AiIcon(),
              selectedIcon: _AiIcon(),
              label: 'RYSE AI',
            ),
            const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Menu',
            ),
          ],
        ),
      ),
    );
  }
}

/// The AI tab keeps the brand gradient in every state.
class _AiIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          const LinearGradient(colors: AppColors.aiGradient).createShader(bounds),
      child: const Icon(Icons.auto_awesome, color: Colors.white),
    );
  }
}
