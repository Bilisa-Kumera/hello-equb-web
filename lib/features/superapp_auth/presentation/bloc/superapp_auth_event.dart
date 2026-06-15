import 'package:equatable/equatable.dart';

abstract class SuperAppAuthEvent extends Equatable {
  const SuperAppAuthEvent();

  @override
  List<Object?> get props => [];
}

class SuperAppAuthStarted extends SuperAppAuthEvent {
  const SuperAppAuthStarted({
    required this.appToken,
    required this.phoneNumber,
  });

  final String appToken;
  final String phoneNumber;

  @override
  List<Object?> get props => [appToken, phoneNumber];
}
