import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pops the route when possible; otherwise sends the user back to the
/// dashboard. Use this as the `leading` widget of any sub-screen AppBar
/// so the user is never stuck because go_router replaced the stack.
class BackOrHomeButton extends StatelessWidget {
  const BackOrHomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Back',
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
    );
  }
}
