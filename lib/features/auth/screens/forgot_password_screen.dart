import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:dir_delivery_driver/features/auth/domain/enums/verification_from_enum.dart';
import 'package:dir_delivery_driver/features/auth/screens/sign_up_screen.dart';
import 'package:dir_delivery_driver/features/splash/controllers/splash_controller.dart';
import 'package:dir_delivery_driver/helper/display_helper.dart';
import 'package:dir_delivery_driver/helper/svg_image_helper.dart';
import 'package:dir_delivery_driver/util/dimensions.dart';
import 'package:dir_delivery_driver/util/images.dart';
import 'package:dir_delivery_driver/util/styles.dart';
import 'package:dir_delivery_driver/features/auth/controllers/auth_controller.dart';
import 'package:dir_delivery_driver/features/auth/screens/verification_screen.dart';
import 'package:dir_delivery_driver/common_widgets/app_bar_widget.dart';
import 'package:dir_delivery_driver/common_widgets/button_widget.dart';
import 'package:dir_delivery_driver/common_widgets/text_field_widget.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  TextEditingController phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBarWidget(title: 'forget_password'.tr, showBackButton: true, regularAppbar: true),
        body: GetBuilder<AuthController>(builder: (authController) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Dimensions.orderStatusIconHeight),
                    FutureBuilder<String>(
                        future: loadSvgAndChangeColors(Images.forgetPasswordGraphics, Theme.of(context).primaryColor),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                            return SvgPicture.string(snapshot.data!);
                          }
                          return SvgPicture.asset(Images.forgetPasswordGraphics);
                        }),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Text(
                      'forget_your_password'.tr,
                      style: textBold.copyWith(fontSize: Dimensions.fontSizeTwenty),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Text(
                      'enter_your_phone_to_receive_a_reset_code'.tr,
                      style: textMedium.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          fontSize: Dimensions.fontSizeSmall),
                      maxLines: 2,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSignUp),
                    TextFieldWidget(
                      hintText: 'enter_your_phone'.tr,
                      inputType: TextInputType.number,
                      countryDialCode: authController.countryDialCode,
                      controller: phoneController,
                      onCountryChanged: (CountryCode countryCode) {
                        authController.countryDialCode = countryCode.dialCode!;
                        authController.setCountryCode(countryCode.dialCode!);
                      },
                      autoFocus: phoneController.text.isEmpty,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                    authController.isOtpSending
                        ? Center(child: SpinKitCircle(color: Theme.of(context).primaryColor, size: 40.0))
                        : ButtonWidget(
                            buttonText: 'get_otp'.tr,
                            radius: 50,
                            onPressed: () {
                              String phoneNumber = phoneController.text;
                              if (phoneNumber.isEmpty) {
                                showCustomSnackBar('phone_is_required'.tr);
                              } else {
                                if (Get.find<SplashController>().config?.isFirebaseOtpVerification ?? false) {
                                  authController.firebaseOtpSend(
                                      countryCode: authController.countryDialCode,
                                      number: phoneNumber,
                                      from: VerificationForm.reset);
                                } else if (Get.find<SplashController>().config?.isSmsGateway ?? false) {
                                  authController
                                      .sendOtp(countryCode: authController.countryDialCode, number: phoneNumber)
                                      .then((value) {
                                    if (value.statusCode == 200) {
                                      Get.to(() => VerificationScreen(
                                            countryCode: authController.countryDialCode,
                                            number: phoneNumber,
                                            form: VerificationForm.reset,
                                          ));
                                    }
                                  });
                                } else {
                                  showCustomSnackBar('sms_gateway_not_integrate'.tr);
                                }
                              }
                            },
                          ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    (Get.find<SplashController>().config!.selfRegistration != null &&
                            Get.find<SplashController>().config!.selfRegistration!)
                        ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(
                              '${'do_not_have_an_account'.tr} ',
                              style: textMedium.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Get.to(() => const SignUpScreen()),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'join_as_driver'.tr,
                                style: textMedium.copyWith(
                                  decoration: TextDecoration.underline,
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).primaryColor,
                                  decorationColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ])
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text("${'to_create_account'.tr} "),
                            InkWell(
                              onTap: () => Get.find<SplashController>().sendMailOrCall(
                                "tel:${Get.find<SplashController>().config?.businessContactPhone}",
                                false,
                              ),
                              child: Text(
                                "${'contact_support'.tr} ",
                                style: textRegular.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ]),
                  ]),
            ),
          );
        }),
      ),
    );
  }
}
