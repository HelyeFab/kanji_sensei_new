import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

abstract class SomeRepository {
  Future<Either<Exception, int>> fetchData();
}

class MockSomeRepository extends Mock implements SomeRepository {
  @override
  Future<Either<Exception, int>> fetchData() => 
      super.noSuchMethod(Invocation.method(#fetchData, []));
}

void main() {
  late MockSomeRepository mockRepository;

  setUp(() {
    mockRepository = MockSomeRepository();
  });

  test('Mocktail and Either test', () async {
    when(() => mockRepository.fetchData())
        .thenAnswer((_) async => const Right(42));

    final result = await mockRepository.fetchData();

    expect(result, const Right(42));
    verify(() => mockRepository.fetchData());
  });
}
