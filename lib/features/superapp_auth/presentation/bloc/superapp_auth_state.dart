import 'package:equatable/equatable.dart';

abstract class SuperAppAuthState extends Equatable {
  const SuperAppAuthState();

  @override
  List<Object?> get props => [];
}

class SuperAppAuthInitial extends SuperAppAuthState {
  const SuperAppAuthInitial();
}

class SuperAppAuthNotInSuperApp extends SuperAppAuthState {
  const SuperAppAuthNotInSuperApp();
}

class SuperAppAuthInProgress extends SuperAppAuthState {
  const SuperAppAuthInProgress();
}

class SuperAppAuthSuccess extends SuperAppAuthState {
  const SuperAppAuthSuccess();
}

class SuperAppAuthFailure extends SuperAppAuthState {
  const SuperAppAuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
