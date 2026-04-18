import 'package:flutter_test/flutter_test.dart';

// CARD-01: Tapping a card in CardSwipeScreen navigates to CardDetailScreen.
// Full integration test requires a running router and mock repository.
// Implemented as a skip-stub here; full test in Phase 5 integration suite.

void main() {
  group('CardSwipeScreen tap-to-detail (CARD-01)', () {
    testWidgets(
      'tapping _CardFaceWidget navigates to /card/:id with card as extra',
      (tester) async {
        // TODO(phase4): pump CardSwipeScreen with mocked cardRepositoryProvider,
        // tap the card widget, verify GoRouter navigated to /card/:id and
        // state.extra is a MagicCard.
      },
      skip: true,
    );

    testWidgets(
      'tapping favourite card face in FavouriteSwipeScreen fetches full card and navigates',
      (tester) async {
        // TODO(phase4): pump FavouriteSwipeScreen with mocked cardRepositoryProvider
        // returning a full MagicCard, tap the card face, verify navigation to /card/:id.
      },
      skip: true,
    );
  });
}
