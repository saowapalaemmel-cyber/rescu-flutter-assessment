import 'dart:async';

import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../util/log_service.dart';

class SearchDealsController extends GetxController {
  final DealRepo dealRepo;

  SearchDealsController({required this.dealRepo});

  final results = <DealModel>[].obs;
  final isLoading = false.obs;
  final hasSearched = false.obs;

  // Prevent one keystroke from starting an unnecessary search request.
  Timer? _debounceTimer;

  // A response is valid only for the query generation that started it.
  int _searchGeneration = 0;

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    final generation =  ++_searchGeneration;

    if (query.trim().isEmpty) {
      results.clear();
      isLoading.value = false;
      hasSearched.value = false;
      return;
    }

    // Wait until typing pauses before starting the simulated API request.
    _debounceTimer = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_search(query, generation)),
    );
  }

  Future<void> _search(String query, int generation) async {
    isLoading.value = true;
    hasSearched.value = true;

    try {
      final found = await dealRepo.search(query);

      // Ignore slow responses that belong to an older query.
      if (generation == _searchGeneration) {
        results.assignAll(found);
      }
    } catch (e) {
      // Do not log an obsolete failure for the query the user replaced.
      if (generation == _searchGeneration) {
        LogService.error('search failed', e);
      }
    } finally {
      // Only the latest request may change the current loading state.
      if (generation == _searchGeneration) {
        isLoading.value = false;
      }
    }
  }

  @override
  void onClose() {
    // Avoid pending callbacks or late responses after the controller is closed.
    _debounceTimer?.cancel();
    _searchGeneration++;
    super.onClose();
  }
}
