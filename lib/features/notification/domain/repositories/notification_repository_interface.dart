import 'package:dir_delivery_driver/Interface/repository_interface.dart';

abstract class NotificationRepositoryInterface implements RepositoryInterface {
  Future<dynamic> sendReadStatus(int notificationId);
}
