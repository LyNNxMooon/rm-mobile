import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/onboarding/domain/use_cases/get_terms_accepted.dart';
import 'package:rmstock_scanner/features/onboarding/domain/use_cases/set_terms_accepted.dart';

abstract class OnboardingEvent {}

class LoadOnboardingStatusEvent extends OnboardingEvent {}

class SetTermsAcceptedEvent extends OnboardingEvent {
  final bool accepted;

  SetTermsAcceptedEvent(this.accepted);
}

abstract class OnboardingState {}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class OnboardingLoaded extends OnboardingState {
  final bool termsAccepted;

  OnboardingLoaded(this.termsAccepted);
}

class OnboardingError extends OnboardingState {
  final String message;

  OnboardingError(this.message);
}

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final GetTermsAccepted getTermsAccepted;
  final SetTermsAccepted setTermsAccepted;

  OnboardingBloc({
    required this.getTermsAccepted,
    required this.setTermsAccepted,
  }) : super(OnboardingInitial()) {
    on<LoadOnboardingStatusEvent>(_onLoadStatus);
    on<SetTermsAcceptedEvent>(_onSetAccepted);
  }

  Future<void> _onLoadStatus(
    LoadOnboardingStatusEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    try {
      final accepted = await getTermsAccepted();
      emit(OnboardingLoaded(accepted));
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }

  Future<void> _onSetAccepted(
    SetTermsAcceptedEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    try {
      await setTermsAccepted(event.accepted);
      emit(OnboardingLoaded(event.accepted));
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }
}
