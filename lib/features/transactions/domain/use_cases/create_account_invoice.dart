import '../../../../utils/internet_connection_utils.dart';
import '../../../../entities/response/invoice_response.dart';
import '../repositories/sales_repo.dart';

class CreateAccountInvoice {
  final SalesRepo repository;

  CreateAccountInvoice(this.repository);

  Future<InvoiceResponse> call(Map<String, dynamic> body) async {
    if (!await InternetConnectionUtils.instance.checkInternetConnection()) {
      return Future.error("Please connect to a network!");
    }

    return repository.createAccountInvoice(body);
  }
}
