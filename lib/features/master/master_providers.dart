import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/marketplace.dart';
import '../marketplace/marketplace_providers.dart';

final myMasterProvider = FutureProvider.autoDispose<Master?>(
  (ref) => ref.watch(marketplaceRepositoryProvider).fetchMyMaster(),
);

final masterRequestsProvider = StreamProvider.autoDispose
    .family<List<ServiceRequest>, String>(
      (ref, masterId) => ref
          .watch(marketplaceRepositoryProvider)
          .watchMasterRequests(masterId),
    );
