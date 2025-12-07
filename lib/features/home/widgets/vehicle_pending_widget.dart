import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dir_delivery_driver/common_widgets/button_widget.dart';
import 'package:dir_delivery_driver/features/home/screens/vehicle_add_screen.dart';
import 'package:dir_delivery_driver/features/profile/controllers/profile_controller.dart';
import 'package:dir_delivery_driver/features/splash/controllers/splash_controller.dart';
import 'package:dir_delivery_driver/util/dimensions.dart';
import 'package:dir_delivery_driver/util/images.dart';
import 'package:dir_delivery_driver/util/styles.dart';

class VehiclePendingWidget extends StatelessWidget {
  const VehiclePendingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          border: Border.all(width: .5, color: Theme.of(context).primaryColor)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
          child: Text(
            'create_account_approve_description_vehicle'.tr,
            style: textMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
          child: Text(
            Get.find<ProfileController>().profileInfo?.vehicle?.vehicleRequestStatus == 'pending'
                ? 'registration_not_approve_yet_vehicle'.tr
                : '${'your_vehicle_request_denied_by'.tr} ${Get.find<SplashController>().config?.businessName} ${'. please_recheck_and_update_vehicle_info'.tr}',
            style: textRegular.copyWith(color: Theme.of(context).hintColor),
            textAlign: TextAlign.center,
          ),
        ),
        Image.asset(Images.reward1),
        Get.find<ProfileController>().profileInfo?.vehicle?.vehicleRequestStatus == 'pending'
            ? const SizedBox(height: Dimensions.paddingSizeDefault)
            : Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeOver, vertical: Dimensions.paddingSizeDefault),
                child: ButtonWidget(
                  buttonText: 'update_vehicle_info'.tr,
                  onPressed: () =>
                      Get.to(() => VehicleAddScreen(vehicleInfo: Get.find<ProfileController>().profileInfo?.vehicle)),
                ),
              )
      ]),
    );
  }
}
