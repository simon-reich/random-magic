import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_magic/features/card_discovery/presentation/card_swipe_screen.dart';
import 'package:random_magic/features/filters/presentation/providers.dart';

// Wave 0 stubs — all test bodies are skipped until Plan 05 implements the
// ActiveFilterBar widget on the CardSwipeScreen (DISC-10).

void main() {
  group('ActiveFilterBar — hidden when no filters (DISC-10)', () {
    test('no FilterChip visible when filter state is empty', () {
      expect(true, true, skip: 'Wave 0 stub — implement in Plan 05');
    });
  });

  group('ActiveFilterBar — shows chips when filters active (DISC-10)', () {
    test('FilterChip visible for each active filter value', () {
      expect(true, true, skip: 'Wave 0 stub — implement in Plan 05');
    });
  });

  group('ActiveFilterBar — chip tap removes filter (DISC-10)', () {
    test('tapping chip updates provider state to remove that filter', () {
      expect(true, true, skip: 'Wave 0 stub — implement in Plan 05');
    });
  });
}
