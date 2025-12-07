import 'package:get/get_connect/http/src/response/response.dart';
import 'package:dir_delivery_driver/Interface/repository_interface.dart';

abstract class OutOfZoneRepositoryInterface implements RepositoryInterface {
  Future<Response> getZoneList();
}
