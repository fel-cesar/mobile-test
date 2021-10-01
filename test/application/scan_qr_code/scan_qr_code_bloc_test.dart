import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:superformula_mobile_test/application/scan_qr_code/scan_qr_code_bloc.dart';
import 'package:superformula_mobile_test/domain/display_qr_code/qr_seed_failure.dart';
import '../../setup/test_helpers.dart';

void main() {
  group('ScanQrCodeBloc -', () {
    setUp(registerServices);
    tearDown(unregisterServices);
    const seed = 'd43397d129c3de9e4b6c3974c1c16d1f';

    group('validateQrCodeData -', () {
      test('Should validate qr code data', () async {
        // arrange
        final mockRepository = getAndRegisterIQrSeedRepository(data: seed);
        getAndRegisterNetworkInfo();
        final bloc = ScanQrCodeBloc(mockRepository);

        // act
        bloc.add(const ScanQrCodeEvent.qrCodeScanned(seed));
        await untilCalled(mockRepository.validateQrCodeData(seed));

        // assert
        verify(mockRepository.validateQrCodeData(seed));
      });

      test(
          'When there is no connection, emits a "Server Error message" in the state',
          () async {
        getAndRegisterNetworkInfo(isConnected: false);
        // arrange
        final bloc = ScanQrCodeBloc(getAndRegisterIQrSeedRepository(
            failure: const QrSeedFailure.serverFailure(), data: seed));

        // assert later
        final expected = [
          const ScanQrCodeState(code: '', isValidating: true, message: null),
          const ScanQrCodeState(
              code: '',
              isValidating: false,
              message: 'Server error. Please try again.'),
        ];

        // ignore: unawaited_futures
        expectLater(bloc.stream, emitsInOrder(expected));

        // act
        bloc.add(const ScanQrCodeEvent.qrCodeScanned(seed));
      });

      test(
          'When data is invalid, emits [{...validating: true}, {...isValidating: false, message}]',
          () async {
        // arrange
        final bloc = ScanQrCodeBloc(
            getAndRegisterIQrSeedRepository(data: seed, isValid: false));

        // assert later
        const expected = [
          ScanQrCodeState(code: '', isValidating: true, message: null),
          ScanQrCodeState(
              code: seed,
              isValidating: false,
              message: 'Code is invalid. Please try another code.'),
        ];

        // ignore: unawaited_futures
        expectLater(bloc.stream, emitsInOrder(expected));

        // act
        bloc.add(const ScanQrCodeEvent.qrCodeScanned(seed));
      });
      test(
          'When data is valid, emits [{...validating: true}, {...isValidating: false}]',
          () async {
        // arrange
        final bloc =
            ScanQrCodeBloc(getAndRegisterIQrSeedRepository(data: seed));

        // assert later
        const expected = [
          ScanQrCodeState(code: '', isValidating: true, message: null),
          ScanQrCodeState(
              code: seed, isValidating: false, message: 'Code is valid $seed'),
        ];

        // ignore: unawaited_futures
        expectLater(bloc.stream, emitsInOrder(expected));

        // act
        bloc.add(const ScanQrCodeEvent.qrCodeScanned(seed));
      });
    });
    group('QrView Camera-', () {
      test(
          'When data camera not loaded, emits [{ message: true}, {...isValidating: false}]',
          () async {
        // arrange
        final bloc = ScanQrCodeBloc(getAndRegisterIQrSeedRepository(data: ''));

        // assert later
        const expected = [
          // ScanQrCodeState(code: '', isValidating: true, message: null),
          ScanQrCodeState(
              code: '',
              isValidating: false,
              message: 'Unable to access the device camera.'),
        ];

        // ignore: unawaited_futures
        expectLater(bloc.stream, emitsInOrder(expected));

        // act
        bloc.add(const ScanQrCodeEvent.cameraLoadFailed());
      });
    });
  });
}
