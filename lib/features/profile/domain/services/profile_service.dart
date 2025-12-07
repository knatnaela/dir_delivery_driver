import 'package:image_picker/image_picker.dart';
import 'package:dir_delivery_driver/data/api_client.dart';
import 'package:dir_delivery_driver/features/profile/domain/models/vehicle_body.dart';
import 'package:dir_delivery_driver/features/profile/domain/repositories/profile_repository_interface.dart';
import 'package:dir_delivery_driver/features/profile/domain/services/profile_service_interface.dart';

class ProfileService implements ProfileServiceInterface {
  final ProfileRepositoryInterface profileRepositoryInterface;
  ProfileService({required this.profileRepositoryInterface});

  @override
  Future addNewVehicle(VehicleBody vehicleBody, List<MultipartDocument> file) {
    return profileRepositoryInterface.addNewVehicle(vehicleBody, file);
  }

  @override
  Future updateVehicle(VehicleBody vehicleBody, String driverId) {
    return profileRepositoryInterface.updateVehicle(vehicleBody, driverId);
  }

  @override
  Future dailyLog() {
    return profileRepositoryInterface.dailyLog();
  }

  @override
  Future getCategoryList(int offset) {
    return profileRepositoryInterface.getCategoryList(offset);
  }

  @override
  Future getProfileInfo() {
    return profileRepositoryInterface.getProfileInfo();
  }

  @override
  Future getVehicleBrandList(int offset) {
    return profileRepositoryInterface.getVehicleBrandList(offset);
  }

  @override
  Future getVehicleModelList(int offset) {
    return profileRepositoryInterface.getVehicleModelList(offset);
  }

  @override
  Future profileOnlineOffline() {
    return profileRepositoryInterface.profileOnlineOffline();
  }

  @override
  Future updateProfileInfo(
      String firstName,
      String lastname,
      String email,
      String identityType,
      String identityNumber,
      XFile? profile,
      List<MultipartBody>? identityImage,
      List<String> services,
      List<String> oldDocuments,
      List<MultipartDocument> newDocuments) {
    return profileRepositoryInterface.updateProfileInfo(firstName, lastname, email, identityType, identityNumber,
        profile, identityImage, services, oldDocuments, newDocuments);
  }

  @override
  Future getProfileLevelInfo() {
    return profileRepositoryInterface.getProfileLevelInfo();
  }
}
