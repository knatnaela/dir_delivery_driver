import 'package:get/get_connect/http/src/response/response.dart';
import 'package:dir_delivery_driver/Interface/repository_interface.dart';

abstract class LeaderBoardRepositoryInterface implements RepositoryInterface {
  Future<Response?> getDailyActivity();
  Future<Response?> getLeaderBoardList({int? offset = 1, required String selectedFilterName});
}
