import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Compatibility entry point that routes every deposit action through the
/// canonical Receive flow.
abstract final class UnifiedDepositSheet {
  static Future<void> show(BuildContext context) async {
    await context.push<void>('/receive');
  }
}
