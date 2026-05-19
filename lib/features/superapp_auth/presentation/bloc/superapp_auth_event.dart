import 'package:equatable/equatable.dart';

abstract class SuperAppAuthEvent extends Equatable {
  const SuperAppAuthEvent();

  @override
  List<Object?> get props => [];
}

class SuperAppAuthStarted extends SuperAppAuthEvent {
  const SuperAppAuthStarted({required this.merchantAppId});

  final String merchantAppId;

  @override
  List<Object?> get props => [merchantAppId];
}
