import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import '../../data/api/kanji_api_service.dart';
import '../../data/api/kanji_local_data_service.dart';
import '../../data/repositories/kanji_repository_impl.dart';
import '../../domain/repositories/kanji_repository.dart';
import '../../presentation/blocs/kanji/kanji_bloc.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() {
  // Manual registration until code generation is set up
  _registerDependencies();
}

void _registerDependencies() {
  // Register Services
  getIt.registerLazySingleton<KanjiApiService>(() => KanjiApiService());
  getIt.registerLazySingleton<KanjiLocalDataService>(() => KanjiLocalDataService());
  
  // Register Repository
  getIt.registerLazySingleton<KanjiRepository>(
    () => KanjiRepositoryImpl(
      getIt<KanjiApiService>(),
      getIt<KanjiLocalDataService>(),
    )
  );
  
  // Register Bloc
  getIt.registerFactory<KanjiBloc>(
    () => KanjiBloc(getIt<KanjiRepository>())
  );
}
