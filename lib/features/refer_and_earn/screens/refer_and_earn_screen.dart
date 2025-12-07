import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dir_delivery_driver/common_widgets/app_bar_widget.dart';
import 'package:dir_delivery_driver/features/dashboard/screens/dashboard_screen.dart';
import 'package:dir_delivery_driver/features/profile/controllers/profile_controller.dart';
import 'package:dir_delivery_driver/features/refer_and_earn/controllers/refer_and_earn_controller.dart';
import 'package:dir_delivery_driver/features/refer_and_earn/screens/referral_details_screen.dart';
import 'package:dir_delivery_driver/features/refer_and_earn/screens/referral_earning_screen.dart';
import 'package:dir_delivery_driver/features/refer_and_earn/widgets/referral_type_button_widget.dart';
import 'package:dir_delivery_driver/util/dimensions.dart';

class ReferAndEarnScreen extends StatefulWidget {
  const ReferAndEarnScreen({super.key});

  @override
  State<ReferAndEarnScreen> createState() => _ReferAndEarnScreenState();
}

class _ReferAndEarnScreenState extends State<ReferAndEarnScreen> {
  @override
  void initState() {
    Get.find<ReferAndEarnController>().getEarningHistoryList(1);
    Get.find<ReferAndEarnController>().getReferralDetails();
    Get.find<ProfileController>().getProfileInfo();
    Get.find<ReferAndEarnController>().setReferralTypeIndex(0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (res, val) {
          if (Get.find<ReferAndEarnController>().referralTypeIndex == 1) {
            Get.find<ReferAndEarnController>().setReferralTypeIndex(0, isUpdate: true);
          } else {
            if (!res) {
              if (Navigator.canPop(context)) {
                Get.back();
              } else {
                Get.offAll(() => const DashboardScreen());
              }
            }
          }
        },
        child: Scaffold(
          body: GetBuilder<ReferAndEarnController>(builder: (referAndEarnController) {
            return Stack(children: [
              Column(children: [
                AppBarWidget(
                  title: 'refer&earn'.tr,
                  onBackPressed: () {
                    if (Get.find<ReferAndEarnController>().referralTypeIndex == 1) {
                      Get.find<ReferAndEarnController>().setReferralTypeIndex(0, isUpdate: true);
                    } else {
                      Get.back();
                    }
                  },
                ),
                const SizedBox(height: Dimensions.topBelowSpace),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Expanded(
                    child: referAndEarnController.referralTypeIndex == 0
                        ? const ReferralDetailsScreen()
                        : const ReferralEarningScreen()),
              ]),
              Positioned(
                top: Get.height * (GetPlatform.isIOS ? 0.14 : 0.11),
                left: Dimensions.paddingSizeSmall,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(
                    height: Dimensions.headerCardHeight,
                    child: Center(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        scrollDirection: Axis.horizontal,
                        itemCount: referAndEarnController.referralType.length,
                        itemBuilder: (context, index) {
                          return SizedBox(
                              width: Get.width / 2.1,
                              child: ReferralTypeButtonWidget(
                                index: index,
                                referralType: referAndEarnController.referralType[index],
                              ));
                        },
                      ),
                    ),
                  ),
                ]),
              )
            ]);
          }),
        ),
      ),
    );
  }
}
