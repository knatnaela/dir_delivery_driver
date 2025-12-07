import 'package:get/get.dart';
import 'package:dir_delivery_driver/features/maintainance_mode/screens/maintainance_screen.dart';
import 'package:dir_delivery_driver/features/profile/controllers/profile_controller.dart';
import 'package:dir_delivery_driver/features/ride/controllers/ride_controller.dart';
import 'package:dir_delivery_driver/features/splash/controllers/splash_controller.dart';
import 'package:dir_delivery_driver/helper/pusher_helper.dart';

class HomeScreenHelper {
  void checkMaintanenceMode() {
    int ridingCount =
        (Get.find<RideController>().ongoingTrip == null || Get.find<RideController>().ongoingTrip!.isEmpty)
            ? 0
            : (Get.find<RideController>().ongoingTrip![0].currentStatus == 'ongoing' ||
                    Get.find<RideController>().ongoingTrip![0].currentStatus == 'accepted' ||
                    (Get.find<RideController>().ongoingTrip![0].currentStatus == 'completed' &&
                        Get.find<RideController>().ongoingTrip![0].paymentStatus == 'unpaid') ||
                    (Get.find<RideController>().ongoingTrip![0].currentStatus == 'cancelled' &&
                            Get.find<RideController>().ongoingTrip![0].paymentStatus == 'unpaid' &&
                            Get.find<RideController>().ongoingTrip![0].cancelledBy == 'customer') &&
                        Get.find<RideController>().ongoingTrip![0].type != 'parcel')
                ? 1
                : 0;
    int parcelCount = Get.find<RideController>().parcelListModel?.totalSize ?? 0;

    if (ridingCount == 0 && parcelCount == 0) {
      Get.find<SplashController>().saveOngoingRides(false);
      if (Get.find<SplashController>().config!.maintenanceMode != null &&
          Get.find<SplashController>().config!.maintenanceMode!.maintenanceStatus == 1 &&
          Get.find<SplashController>().config!.maintenanceMode!.selectedMaintenanceSystem!.driverApp == 1) {
        Get.offAll(() => const MaintenanceScreen());
      }
    } else {
      Get.find<SplashController>().saveOngoingRides(true);
    }
  }

  void pendingListPusherImplementation() {
    for (int i = 0; i < Get.find<RideController>().getPendingRideRequestModel!.data!.length; i++) {
      PusherHelper().customerInitialTripCancel(
          Get.find<RideController>().getPendingRideRequestModel!.data![i].id!, Get.find<ProfileController>().driverId);
      PusherHelper().anotherDriverAcceptedTrip(
          Get.find<RideController>().getPendingRideRequestModel!.data![i].id!, Get.find<ProfileController>().driverId);
    }
  }

  void ongoingLastRidePusherImplementation() {
    List<String> data = ["ongoing", "accepted"];

    for (int i = 0; i < Get.find<RideController>().ongoingRideList!.length; i++) {
      if (data.contains(Get.find<RideController>().ongoingRideList![i].currentStatus)) {
        PusherHelper().tripCancelAfterOngoing(Get.find<RideController>().ongoingRideList![i].id!);
        PusherHelper().customerInitialTripCancel(
            Get.find<RideController>().ongoingRideList![i].id!, Get.find<ProfileController>().driverId);
        PusherHelper().tripPaymentSuccessful(Get.find<RideController>().ongoingRideList![i].id!);
      }
    }
  }

  void ongoingParcelListPusherImplementation() {
    List<String> data = ["ongoing", "accepted"];

    for (int i = 0; i < Get.find<RideController>().parcelListModel!.data!.length; i++) {
      if (data.contains(Get.find<RideController>().parcelListModel!.data![i].currentStatus)) {
        PusherHelper().tripCancelAfterOngoing(Get.find<RideController>().parcelListModel!.data![i].id!);
        PusherHelper().customerInitialTripCancel(
            Get.find<RideController>().parcelListModel!.data![i].id!, Get.find<ProfileController>().driverId);
        PusherHelper().tripPaymentSuccessful(Get.find<RideController>().parcelListModel!.data![i].id!);
      }
    }
  }
}
