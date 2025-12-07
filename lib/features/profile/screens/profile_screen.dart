import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dir_delivery_driver/features/dashboard/screens/dashboard_screen.dart';
import 'package:dir_delivery_driver/features/home/screens/vehicle_add_screen.dart';
import 'package:dir_delivery_driver/features/profile/widgets/profile_details_widget.dart';
import 'package:dir_delivery_driver/features/profile/widgets/profile_level_details_widget.dart';
import 'package:dir_delivery_driver/features/profile/widgets/vehicle_details_widget.dart';
import 'package:dir_delivery_driver/features/wallet/controllers/wallet_controller.dart';
import 'package:dir_delivery_driver/localization/localization_controller.dart';
import 'package:dir_delivery_driver/util/dimensions.dart';
import 'package:dir_delivery_driver/util/styles.dart';
import 'package:dir_delivery_driver/features/profile/controllers/profile_controller.dart';
import 'package:dir_delivery_driver/features/profile/screens/edit_profile_screen.dart';
import 'package:dir_delivery_driver/features/profile/widgets/profile_type_button_widget.dart';
import 'package:dir_delivery_driver/features/splash/controllers/splash_controller.dart';
import 'package:dir_delivery_driver/common_widgets/app_bar_widget.dart';
import 'package:dir_delivery_driver/common_widgets/image_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    Get.find<ProfileController>().getProfileLevelInfo();
    Get.find<ProfileController>().getProfileInfo();
    Get.find<WalletController>().getLoyaltyPointList(1);
    Get.find<ProfileController>().setProfileTypeIndex(0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (res, val) {
          if (Get.find<ProfileController>().profileTypeIndex == 0) {
            if (!res) {
              if (Navigator.canPop(context)) {
                Get.back();
              } else {
                Get.offAll(() => const DashboardScreen());
              }
            }
          } else {
            Get.find<ProfileController>().moveToPreviousProfileType();
          }
        },
        child: Scaffold(
          body: GetBuilder<ProfileController>(builder: (profileController) {
            return Stack(children: [
              Column(children: [
                AppBarWidget(
                  title: 'profile'.tr,
                  showBackButton: true,
                  onTap: () => Get.find<ProfileController>().toggleDrawer(),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeDefault,
                    0,
                  ),
                  child: SingleChildScrollView(
                      child: Stack(children: [
                    Column(children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: .25), width: .5),
                          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                          child: profileController.profileTypeIndex != 2
                              ? ImageWidget(
                                  width: 80,
                                  height: 80,
                                  image: '${Get.find<SplashController>().config!.imageBaseUrl!.profileImage}/'
                                      '${profileController.profileInfo!.profileImage!}',
                                )
                              : profileController.profileInfo!.vehicle != null
                                  ? ImageWidget(
                                      width: 80,
                                      height: 80,
                                      image: '${Get.find<SplashController>().config!.imageBaseUrl!.vehicleCategory}/'
                                          '${profileController.profileInfo!.vehicle!.category!.image}',
                                    )
                                  : const SizedBox(),
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Text(
                        profileController.profileTypeIndex != 2
                            ? '${profileController.profileInfo?.firstName ?? ''}  '
                                '${profileController.profileInfo?.lastName ?? ''}'
                            : '${profileController.profileInfo?.vehicle?.brand?.name ?? ''} ${profileController.profileInfo?.vehicle?.model?.name ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textBold.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontSize: Dimensions.fontSizeLarge,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      profileController.profileTypeIndex != 2
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(
                                '${profileController.profileInfo!.avgRatting.toString()} ',
                              ),
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.orange,
                                size: Dimensions.iconSizeSmall,
                              ),
                              Text('(${'reviews'.tr} ${profileController.profileInfo?.reviewCount})',
                                  style:
                                      textRegular.copyWith(color: Theme.of(context).hintColor.withValues(alpha: 0.5))),
                              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: Dimensions.paddingSizeExtraSmall,
                                  horizontal: Dimensions.paddingSizeSmall,
                                ),
                                decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                                child: Text('${profileController.levelModel?.data?.currentLevel?.name}',
                                    style: textRegular.copyWith(color: Theme.of(context).cardColor)),
                              ),
                            ])
                          : const SizedBox(),
                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                      profileController.profileTypeIndex == 0
                          ? ProfileDetailsWidget()
                          : profileController.profileTypeIndex == 2
                              ? VehicleDetailsWidget()
                              : profileController.profileTypeIndex == 1
                                  ? ProfileLevelDetailsWidget()
                                  : const SizedBox(),
                    ]),
                    if (profileController.profileTypeIndex == 0 ||
                        (profileController.profileTypeIndex == 2 &&
                            profileController.profileInfo?.vehicle?.brand?.name != null))
                      Positioned(
                        right: 0,
                        top: 0,
                        child: InkWell(
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          splashColor: profileController.profileTypeIndex != 1 ? null : Colors.transparent,
                          onTap: () {
                            if (profileController.profileTypeIndex == 0) {
                              Get.to(() => ProfileEditScreen(profileInfo: profileController.profileInfo));
                            } else if (profileController.profileTypeIndex == 2) {
                              Get.to(() => VehicleAddScreen(vehicleInfo: profileController.profileInfo?.vehicle));
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                            decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
                            child: Icon(Icons.edit,
                                size: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor),
                          ),
                        ),
                      )
                  ])),
                ))
              ]),
              Positioned(
                top: Get.height * (GetPlatform.isIOS ? 0.14 : 0.11),
                left: Dimensions.paddingSizeSmall,
                child: SizedBox(
                  height: Get.find<LocalizationController>().isLtr ? 45 : 50,
                  width: Get.width - Dimensions.paddingSizeDefault,
                  child: Center(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      scrollDirection: Axis.horizontal,
                      itemCount: profileController.profileType.length,
                      itemBuilder: (context, index) {
                        if (!(Get.find<SplashController>().config!.levelStatus! == false && index == 1)) {
                          return SizedBox(
                              width: Get.width / 2.3,
                              child: ProfileTypeButtonWidget(
                                profileTypeName: profileController.profileType[index],
                                index: index,
                              ));
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}
