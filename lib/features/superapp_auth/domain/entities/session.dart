import 'package:equatable/equatable.dart';

class Session extends Equatable {
  const Session({
    required this.accessToken,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;

  @override
  List<Object?> get props => [accessToken, refreshToken];
}
