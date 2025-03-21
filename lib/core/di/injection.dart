import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/api/kanji_api_service.dart';
import '../../data/api/kanji_local_data_service.dart';
import '../../data/repositories/kanji_repository_impl.dart';
import '../../data/repositories/saved_words_repository.dart';
import '../../data/repositories/user_stats_repository.dart';
import '../../data/repositories/word_lists_repository.dart';
import '../../domain/repositories/kanji_repository.dart';
import '../../domain/services/spaced_repetition_service.dart';
import '../../core/auth/auth_service.dart';
import '../../presentation/blocs/kanji/kanji_bloc.dart';
import '../../presentation/blocs/kanji/dictionary_search_bloc.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() {
  // Manual registration until code generation is set up
  _registerDependencies();
}

void _registerDependencies() {
  // Register Firebase instances
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  // Register Services
  getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn(
        clientId:
            '93869706966-lrg3q8emmf22d0t83hmno57ilaggcsoj.apps.googleusercontent.com',
        scopes: [
          'email',
          'profile',
        ],
      ));
  getIt.registerLazySingleton<KanjiApiService>(() => KanjiApiService());
  getIt.registerLazySingleton<KanjiLocalDataService>(
      () => KanjiLocalDataService());
  getIt.registerLazySingleton<AuthService>(() => AuthService(
        firebaseAuth: getIt<FirebaseAuth>(),
        googleSignIn: getIt<GoogleSignIn>(),
      ));
  getIt.registerLazySingleton<SpacedRepetitionService>(
      () => SpacedRepetitionService());

  // Register Repositories
  getIt.registerLazySingleton<KanjiRepository>(() => KanjiRepositoryImpl(
        getIt<KanjiApiService>(),
        getIt<KanjiLocalDataService>(),
      ));
  getIt.registerLazySingleton<SavedWordsRepository>(
      () => SavedWordsRepository());
  getIt.registerLazySingleton<UserStatsRepository>(() => UserStatsRepository());
  getIt.registerLazySingleton<WordListsRepository>(() => WordListsRepository());

  // Register Blocs
  getIt.registerFactory<KanjiBloc>(() => KanjiBloc(getIt<KanjiRepository>()));
  getIt.registerLazySingleton<DictionarySearchBloc>(
      () => DictionarySearchBloc(getIt<KanjiRepository>()));
  getIt.registerFactory<AuthBloc>(
      () => AuthBloc(authService: getIt<AuthService>()));
}
