import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dir_delivery_driver/features/trip/controllers/trip_controller.dart';
import 'package:dir_delivery_driver/features/wallet/controllers/wallet_controller.dart';
import 'package:dir_delivery_driver/helper/login_helper.dart';
import 'package:dir_delivery_driver/localization/language_selection_screen.dart';
import 'package:dir_delivery_driver/localization/localization_controller.dart';
import 'package:dir_delivery_driver/util/images.dart';
import 'package:dir_delivery_driver/features/auth/controllers/auth_controller.dart';
import 'package:dir_delivery_driver/features/location/controllers/location_controller.dart';
import 'package:dir_delivery_driver/features/profile/controllers/profile_controller.dart';
import 'package:dir_delivery_driver/features/ride/controllers/ride_controller.dart';
import 'package:dir_delivery_driver/features/splash/controllers/splash_controller.dart';

class SplashScreen extends StatefulWidget {
  final Map<String, dynamic>? notificationData;
  final String? userName;
  const SplashScreen({super.key, this.notificationData, this.userName});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  StreamSubscription<List<ConnectivityResult>>? _onConnectivityChanged;
  late AnimationController _controller;
  late Animation _animation;

  @override
  void initState() {
    super.initState();
    if (!GetPlatform.isIOS) {
      _checkConnectivity();
    }
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _controller.forward();

    Get.find<SplashController>().initSharedData();
    Get.find<TripController>().rideCancellationReasonList();
    Get.find<TripController>().parcelCancellationReasonList();
    Get.find<AuthController>().remainingTime();
    Get.find<WalletController>().getPaymentGetWayList();
    _route();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _onConnectivityChanged?.cancel();
    _animation.removeListener(() {});
    _controller.dispose(); // you
    super.dispose();
  }

  void _checkConnectivity() {
    bool isFirst = true;
    _onConnectivityChanged = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      bool isConnected = result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.mobile);
      if ((isFirst && !isConnected) || !isFirst && context.mounted) {
        ScaffoldMessenger.of(Get.context!).removeCurrentSnackBar();
        ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
        ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
          backgroundColor: isConnected ? Colors.green : Colors.red,
          duration: Duration(seconds: isConnected ? 3 : 6000),
          content: Text(
            isConnected ? 'connected'.tr : 'no_connection'.tr,
            textAlign: TextAlign.center,
          ),
        ));

        if (isConnected) {
          _route();
        }
      }
      isFirst = false;
    });
  }

  void _route() async {
    bool isSuccess = await Get.find<SplashController>().getConfigData();
    if (isSuccess) {
      if (Get.find<LocalizationController>().haveLocalLanguageCode()) {
        LoginHelper().checkLoginRoutes(widget.notificationData, widget.userName);
      } else {
        Get.offAll(() => LanguageSelectionScreen(userName: widget.userName, notificationData: widget.notificationData));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          Images.splashScreenDir,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
