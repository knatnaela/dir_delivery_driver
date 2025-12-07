import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:dir_delivery_driver/features/auth/screens/reset_password_screen.dart';
import 'package:dir_delivery_driver/features/help_and_support/controllers/help_and_support_controller.dart';
import 'package:dir_delivery_driver/features/profile/controllers/profile_controller.dart';
import 'package:dir_delivery_driver/features/profile/widgets/profile_item_widget.dart';
import 'package:dir_delivery_driver/features/splash/controllers/splash_controller.dart';
import 'package:dir_delivery_driver/helper/profile_helper.dart';
import 'package:dir_delivery_driver/localization/localization_controller.dart';
import 'package:dir_delivery_driver/util/dimensions.dart';
import 'package:dir_delivery_driver/util/images.dart';
import 'package:dir_delivery_driver/util/styles.dart';

class ProfileDetailsWidget extends StatefulWidget {
  const ProfileDetailsWidget({super.key});

  @override
  State<ProfileDetailsWidget> createState() => _ProfileDetailsWidgetState();
}

class _ProfileDetailsWidgetState extends State<ProfileDetailsWidget> {
  final ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send!.send([id, status, progress]);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (profileController) {
      return Column(children: [
        Container(
          padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
              color: Theme.of(context).highlightColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.all(Radius.circular(Dimensions.radiusDefault))),
          child: Column(children: [
            if (profileController.profileInfo?.details?.services != null)
              ProfileItemWidget(
                title: 'service',
                value: profileController.profileInfo!.details!.services!.length == 1
                    ? profileController.profileInfo!.details!.services![0].tr
                    : '${profileController.profileInfo!.details!.services![0].tr} & ${profileController.profileInfo!.details!.services![1].tr}',
              ),
            ProfileItemWidget(
              title: 'contact',
              value: Get.find<LocalizationController>().isLtr
                  ? profileController.profileInfo?.phone ?? ''
                  : '${profileController.profileInfo!.phone!.substring(1)}+',
            ),
            ProfileItemWidget(
              title: 'mail_address',
              value: profileController.profileInfo?.email ?? '',
            ),
            ProfileItemWidget(
              title: 'identification_type',
              value: profileController.profileInfo!.identificationType!.tr,
            ),
            ProfileItemWidget(
              title: 'identification_number',
              value: profileController.profileInfo?.identificationNumber ?? '',
              isLastIndex: true,
            ),
          ]),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        if (profileController.profileInfo?.identificationImage != null &&
            profileController.profileInfo!.identificationImage!.isNotEmpty) ...[
          Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                child: Text('identity_images'.tr, style: textBold),
              )),
          GridView.builder(
            padding: EdgeInsets.zero,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: Dimensions.paddingSizeSmall,
              crossAxisSpacing: Dimensions.paddingSize,
            ),
            shrinkWrap: true,
            itemCount: profileController.profileInfo!.identificationImage!.length,
            itemBuilder: (BuildContext context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
                child: Image.network(
                    fit: BoxFit.cover,
                    '${Get.find<SplashController>().config!.imageBaseUrl!.identityImage}/${profileController.profileInfo!.identificationImage![index]}',
                    errorBuilder: (context, url, error) => Image.asset(Images.placeholder, fit: BoxFit.cover)),
              );
            },
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall)
        ],
        if (profileController.profileInfo!.isOldIdentificationImage!) ...[
          Row(children: [
            const SizedBox(width: Dimensions.iconSizeMedium, child: Icon(Icons.error)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text(
              'identity_info_is_pending_for_approval'.tr,
              style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault),
            )
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall)
        ],
        if (profileController.profileInfo?.documents != null &&
            profileController.profileInfo!.documents!.isNotEmpty) ...[
          Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                child: Text('other_documents'.tr, style: textBold),
              )),
          ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: NeverScrollableScrollPhysics(),
            itemCount: profileController.profileInfo!.documents!.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () async {
                  Get.find<HelpAndSupportController>().downloadFile(
                      url:
                          '${Get.find<SplashController>().config!.imageBaseUrl!.documents!}/${profileController.profileInfo!.documents?[index] ?? ''}',
                      fileName: profileController.profileInfo!.documents?[index] ?? '');
                },
                child: Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.all(Radius.circular(Dimensions.paddingSizeSmall))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      Image.asset(
                          ProfileHelper.checkImageExtensions('${profileController.profileInfo!.documents?[index]}'),
                          height: 25,
                          width: 25),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${profileController.profileInfo!.documents?[index]}',
                            style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                        Text('click_to_view_the_file'.tr,
                            style: textRegular.copyWith(
                                fontSize: Dimensions.fontSizeExtraSmall,
                                color: Theme.of(context).hintColor.withValues(alpha: 0.7)))
                      ])
                    ]),
                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(Dimensions.paddingSizeExtraSmall)),
                          border: Border.all(color: Theme.of(context).primaryColor)),
                      child: Image.asset(Images.downloadIcon,
                          height: 10, width: 10, color: Theme.of(context).primaryColor),
                    )
                  ]),
                ),
              );
            },
            separatorBuilder: (context, index) {
              return const SizedBox(height: Dimensions.paddingSizeSmall);
            },
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],
        GestureDetector(
          onTap: () => Get.to(() => const ResetPasswordScreen(
                phoneNumber: '',
                fromChangePassword: true,
              )),
          child: Text('change_password'.tr,
              style: textRegular.copyWith(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  fontSize: Dimensions.fontSizeDefault,
                  decorationColor: Theme.of(context).colorScheme.surfaceContainer,
                  decoration: TextDecoration.underline)),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),
      ]);
    });
  }
}
