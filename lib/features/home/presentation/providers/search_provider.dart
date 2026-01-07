import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../data/search_repository.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchProvider = StreamProvider<List<SearchResult>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final repository = ref.watch(searchRepositoryProvider);

  if (query.length < 2) return Stream.value([]);

  return repository.searchAll(query);
});

// Debounced search logic
final debouncedSearchQueryProvider = StateNotifierProvider<SearchDebouncer, String>((ref) {
  return SearchDebouncer(ref);
});

class SearchDebouncer extends StateNotifier<String> {
  final Ref _ref;
  Timer? _timer;

  SearchDebouncer(this._ref) : super('');

  void update(String query) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), () {
      _ref.read(searchQueryProvider.notifier).state = query;
      state = query;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
