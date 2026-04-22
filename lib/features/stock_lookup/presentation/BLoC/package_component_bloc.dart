import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../entities/vos/stock_vo.dart';
import '../../domain/use_cases/resolve_package_component_stock.dart';

abstract class PackageComponentEvent {}

class ResolvePackageComponentEvent extends PackageComponentEvent {
  final int stockId;
  final String? barcode;
  final String? description;

  ResolvePackageComponentEvent({
    required this.stockId,
    this.barcode,
    this.description,
  });
}

abstract class PackageComponentState {}

class PackageComponentInitial extends PackageComponentState {}

class PackageComponentLoading extends PackageComponentState {}

class PackageComponentResolved extends PackageComponentState {
  final StockVO stock;
  PackageComponentResolved(this.stock);
}

class PackageComponentNotFound extends PackageComponentState {
  final String message;
  PackageComponentNotFound(this.message);
}

class PackageComponentError extends PackageComponentState {
  final String message;
  PackageComponentError(this.message);
}

class PackageComponentBloc
    extends Bloc<PackageComponentEvent, PackageComponentState> {
  final ResolvePackageComponentStock resolvePackageComponentStock;

  PackageComponentBloc({required this.resolvePackageComponentStock})
      : super(PackageComponentInitial()) {
    on<ResolvePackageComponentEvent>(_onResolve);
  }

  Future<void> _onResolve(
    ResolvePackageComponentEvent event,
    Emitter<PackageComponentState> emit,
  ) async {
    emit(PackageComponentLoading());
    try {
      final stock = await resolvePackageComponentStock(
        stockId: event.stockId,
        barcode: event.barcode,
      );

      if (stock != null) {
        emit(PackageComponentResolved(stock));
        return;
      }

      final label = (event.description != null && event.description!.isNotEmpty)
          ? event.description
          : event.barcode;
      emit(PackageComponentNotFound(
        'Stock item "${label ?? event.stockId}" not found in local database. Try syncing stock first.',
      ));
    } catch (e) {
      emit(PackageComponentError(e.toString()));
    }
  }
}
