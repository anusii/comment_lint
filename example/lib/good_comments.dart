// Example of properly formatted comments.

library;

import 'package:flutter/material.dart';

// MAIN FUNCTIONS

/// This is a proper documentation comment.
/// It explains what the function does clearly.
class GoodComments extends StatelessWidget {
  const GoodComments({super.key});

  // This comment has a proper period.

  @override
  Widget build(BuildContext context) {
    // Multi-line comment explaining the logic,
    // where continuation lines don't need periods,
    // but the final line does.

    return const Scaffold(
      body: Center(
        child: Text('Good Comments Example'),
      ),
    );
  }

  // Helper method with proper comment formatting.

  void helperMethod() {
    // Comments ending with colons are handled properly:
    // - First item
    // - Second item

    // This comment describes what happens next.
    print('Hello World');
  }

  // UTILITY METHODS

  /// Returns true if the condition is met.
  bool checkCondition() {
    // Simple comment with period.
    return true;
  }
}
