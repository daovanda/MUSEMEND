import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/core/supabase/supabase_client_provider.dart';
import 'package:musemend/features/profile/data/supabase_profile_repository.dart';
import 'package:musemend/features/profile/domain/account_overview.dart';
import 'package:musemend/features/profile/domain/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(ref.watch(supabaseClientProvider));
});

final accountOverviewProvider = FutureProvider<AccountOverview>((ref) {
  return ref.watch(profileRepositoryProvider).loadOverview();
});
