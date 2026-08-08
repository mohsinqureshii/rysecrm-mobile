import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// One Navigator per tab so drilling into records (Leads, Contacts,
  /// Accounts, Opportunities, Reports, Calendar…) keeps the bottom bar
  /// visible instead of covering it with a full-screen route.
  final List<GlobalKey<NavigatorState>> _navKeys =
      List.generate(5, (_) => GlobalKey<NavigatorState>());

  Widget _rootFor(int i) {
    switch (i) {
      case 0:
        return const HomeScreen();
      case 1:
        return const PipelineScreen();
      case 2:
        return const TasksScreen();
      case 3:
        return const AssistantScreen();
      default:
        return const MenuScreen();
    }
  }

  void _onDestinationSelected(int i) {
    if (i == _index) {
      // Re-tapping the active tab returns it to its root screen.
      _navKeys[i].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _index = i);
    }
  }

  void _handleBack() {
    final navigator = _navKeys[_index].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }
    if (_index != 0) {
      // Any tab falls back to Home before the app can exit.
      setState(() => _index = 0);
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            for (int i = 0; i < _navKeys.length; i++)
              Navigator(
                key: _navKeys[i],
                onGenerateRoute: (settings) => MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => _rootFor(i),
                ),
              ),
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
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _onDestinationSelected,
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
