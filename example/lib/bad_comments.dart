// Example of improperly formatted comments that need fixing

library;

import 'package:flutter/material.dart';

// MAIN FUNCTIONS.  <- This uppercase header shouldn't have a period

/// This is a documentation comment that needs fixing
class BadComments extends StatelessWidget {
  const BadComments({super.key});

  // This comment is missing a period
  @override
  Widget build(BuildContext context) {
    // Multi-line comment that starts properly,
    // but the final line is missing a period

    return const Scaffold(
      body: Center(
        child: Text('Bad Comments Example'),
      ),
    );
  }
  // Missing blank line above - should have space after comment

  void helperMethod() {
    // Comments ending with colons shouldn't have periods:.
    // - First item missing period
    // - Second item also missing period

    // This comment describes what happens next
    print('Hello World');
  }

  // UTILITY METHODS.

  /// Returns true if condition is met
  bool checkCondition() {
    // Simple comment missing period
    return true;
  }
}
