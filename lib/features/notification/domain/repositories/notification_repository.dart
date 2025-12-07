import 'package:get/get_connect/http/src/response/response.dart';
import 'package:dir_delivery_driver/data/api_client.dart';
import 'package:dir_delivery_driver/features/notification/domain/repositories/notification_repository_interface.dart';
import 'package:dir_delivery_driver/util/app_constants.dart';

class NotificationRepository implements NotificationRepositoryInterface {
  final ApiClient apiClient;

  NotificationRepository({required this.apiClient});

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset = 1}) async {
    return await apiClient.getData('${AppConstants.notificationList}$offset');
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    // TODO: implement update
    throw UnimplementedError();
  }

  @override
  Future<Response> sendReadStatus(int notificationId) async {
    return await apiClient.putData(AppConstants.readNotification, {"notification_id": notificationId});
  }
}
