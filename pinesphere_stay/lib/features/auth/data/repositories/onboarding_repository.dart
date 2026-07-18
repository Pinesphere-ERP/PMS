import 'package:fpdart/fpdart.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/core/error/failures.dart';
import 'package:pinesphere_stay/core/network/dio_client.dart';

class OnboardingRepository {
  final Dio _dio;

  OnboardingRepository(this._dio);

  Future<Either<Failure, bool>> registerOwner({
    required String ownerName,
    required String email,
    required String mobileNumber,
    required String password,
    required String businessName,
    required String propertyName,
  }) async {
    try {
      final response = await _dio.post('/onboarding/register', data: {
        'owner_name': ownerName,
        'email': email,
        'mobile_number': mobileNumber,
        'password': password,
        'business_name': businessName,
        'property_name': propertyName,
        'property_type': 'HOTEL',
        'star_category': 'THREE_STAR'
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        return const Right(true);
      }
      return Left(Failure.server(response.data['message'] ?? 'Registration failed'));
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final detail = e.response!.data['detail'];
        return Left(Failure.server(detail is String ? detail : 'Registration failed: ${e.message}'));
      }
      return Left(Failure.server('Network error: ${e.message}'));
    } catch (e) {
      return Left(Failure.server('An unexpected error occurred: $e'));
    }
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return OnboardingRepository(dio);
});
