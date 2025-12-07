import 'package:get/get_connect/http/src/response/response.dart';
import 'package:dir_delivery_driver/data/api_client.dart';
import 'package:dir_delivery_driver/features/leaderboard/domain/repositories/leader_board_repository_interface.dart';
import 'package:dir_delivery_driver/util/app_constants.dart';

class LeaderBoardRepository implements LeaderBoardRepositoryInterface {
  final ApiClient apiClient;

  LeaderBoardRepository({required this.apiClient});

  @override
  Future<Response?> getDailyActivity() async {
    return await apiClient.getData(AppConstants.dailyActivities);
  }

  @override
  Future<Response?> getLeaderBoardList({int? offset = 1, required String selectedFilterName}) async {
    return await apiClient.getData('${AppConstants.leaderboardUri}filter=$selectedFilterName&limit=10&offset=$offset');
  }

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
    // TODO: implement update
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    // TODO: implement update
    throw UnimplementedError();
  }
}
