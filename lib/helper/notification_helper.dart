import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:dir_delivery_driver/features/chat/controllers/chat_controller.dart';
import 'package:dir_delivery_driver/features/chat/screens/message_screen.dart';
import 'package:dir_delivery_driver/features/dashboard/controllers/bottom_menu_controller.dart';
import 'package:dir_delivery_driver/features/help_and_support/controllers/help_and_support_controller.dart';
import 'package:dir_delivery_driver/features/home/screens/parcel_list_screen.dart';
import 'package:dir_delivery_driver/features/home/screens/ride_list_screen.dart';
import 'package:dir_delivery_driver/features/home/widgets/refund_alert_bottomsheet.dart';
import 'package:dir_delivery_driver/features/html/domain/html_enum_types.dart';
import 'package:dir_delivery_driver/features/html/screens/policy_viewer_screen.dart';
import 'package:dir_delivery_driver/features/notification/widgets/receipt_confirmation_bottomsheet.dart';
import 'package:dir_delivery_driver/features/profile/screens/edit_profile_screen.dart';
import 'package:dir_delivery_driver/features/profile/screens/profile_screen.dart';
import 'package:dir_delivery_driver/features/profile/widgets/level_congratulations_dialog_widget.dart';
import 'package:dir_delivery_driver/features/refer_and_earn/controllers/refer_and_earn_controller.dart';
import 'package:dir_delivery_driver/features/refer_and_earn/screens/refer_and_earn_screen.dart';
import 'package:dir_delivery_driver/features/review/screens/review_screen.dart';
import 'package:dir_delivery_driver/features/ride/screens/ride_request_list_screen.dart';
import 'package:dir_delivery_driver/features/safety_setup/controllers/safety_alert_controller.dart';
import 'package:dir_delivery_driver/features/trip/screens/trip_details_screen.dart';
import 'package:dir_delivery_driver/features/wallet/controllers/wallet_controller.dart';
import 'package:dir_delivery_driver/helper/display_helper.dart';
import 'package:dir_delivery_driver/util/app_constants.dart';
import 'package:dir_delivery_driver/features/dashboard/screens/dashboard_screen.dart';
import 'package:dir_delivery_driver/features/map/controllers/map_controller.dart';
import 'package:dir_delivery_driver/features/map/screens/map_screen.dart';
import 'package:dir_delivery_driver/features/profile/controllers/profile_controller.dart';
import 'package:dir_delivery_driver/features/ride/controllers/ride_controller.dart';
import 'package:dir_delivery_driver/features/splash/controllers/splash_controller.dart';
import 'package:dir_delivery_driver/features/trip/screens/payment_received_screen.dart';
import 'package:dir_delivery_driver/features/trip/screens/review_this_customer_screen.dart';
import 'package:dir_delivery_driver/helper/overlay_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationHelper {
  static Future<void> initialize(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    AndroidInitializationSettings androidInitialize = const AndroidInitializationSettings('notification_icon');
    var iOSInitialize = const DarwinInitializationSettings();
    var initializationsSettings = InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    flutterLocalNotificationsPlugin.initialize(
      initializationsSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (kDebugMode) {
          print('Notification response ==> ${response.payload.toString()}');
        }
        // TODO: Route
        try {
          if (response.payload != null && response.payload!.isNotEmpty) {
            if (kDebugMode) {
              print('Notification response ==> ${response.payload.toString()}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Notification response ==> ${response.payload.toString()}');
          }
        }
        return;
      },
      onDidReceiveBackgroundNotificationResponse: myBackgroundMessageReceiver,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      AndroidInitializationSettings androidInitialize = const AndroidInitializationSettings('notification_icon');
      var iOSInitialize = const DarwinInitializationSettings();
      var initializationsSettings = InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
      flutterLocalNotificationsPlugin.initialize(
        initializationsSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          notificationToRoute(message.data);
          return;
        },
        onDidReceiveBackgroundNotificationResponse: myBackgroundMessageReceiver,
      );

      /// Show log for debug
      if (kDebugMode) {
        print('onMessage: ${message.data}');
      }

      /// check maintenance mode
      if (!(Get.find<SplashController>().config!.maintenanceMode != null &&
              Get.find<SplashController>().config!.maintenanceMode!.maintenanceStatus == 1 &&
              Get.find<SplashController>().config!.maintenanceMode!.selectedMaintenanceSystem!.driverApp == 1) ||
          Get.find<SplashController>().haveOngoingRides()) {
        ///Check webSocket connection
        if (Get.find<SplashController>().pusherConnectionStatus == null ||
            Get.find<SplashController>().pusherConnectionStatus == 'Disconnected') {
          if (message.data['action'] == "new_ride_request" || message.data['action'] == "new_parcel_request") {
            _whenNewRequestFound(message);
          } else if (message.data['action'] == "new_message") {
            Get.find<ChatController>().getConversation(message.data['type'], 1);
          } else if (message.data['action'] == "trip_completed") {
            _whenRideComplete(message);
          } else if (message.data['action'] == "bid_accepted") {
            ///Bid Ride Accepted in this case....
            _whenCustomerBidAccept(message);
          } else if (message.data['action'] == "coupon_removed" || message.data['action'] == "coupon_applied") {
            Get.find<RideController>().getFinalFare(message.data['ride_request_id']);
          } else if (message.data['action'] == "payment_successful" && message.data['type'] == "ride_request") {
            _whenRidePaymentSuccess(message);
          } else if (message.data['action'] == "payment_successful" && message.data['type'] == "parcel") {
            Get.find<RideController>().getRideDetails(message.data['ride_request_id']).then((value) {
              if (value.statusCode == 200) {
                Get.find<RideController>().getOngoingParcelList();
                Get.offAll(() => ParcelListScreen(title: 'ongoing_parcel_list'.tr));
              }
            });
          } else if (message.data['action'] == "customer_canceled_trip" ||
              message.data['action'] == "another_driver_assigned") {
            // Close overlay if showing (app might be in background with overlay visible)
            if (GetPlatform.isAndroid) {
              try {
                await OverlayHelper.hideOverlay();
                if (kDebugMode) {
                  print('NotificationHelper: Closing overlay due to trip cancellation');
                }
              } catch (e) {
                if (kDebugMode) {
                  print('NotificationHelper: Error closing overlay on cancel: $e');
                }
              }
            }
            _whenCustomerCancelTrip(message);
          } else if (checkContainsAction(message.data['action'])) {
            Get.find<ProfileController>().getProfileInfo().then((value) {
              if (value.statusCode == 200) {
                Get.find<RiderMapController>().setRideCurrentState(RideState.initial);
                Get.offAll(() => const DashboardScreen());
              }
            });
          } else if (message.data['action'] == "customer_rejected_bid") {
            if ((Get.find<RideController>().ongoingTrip ?? []).isEmpty) {
              Get.offAll(() => const DashboardScreen());
            } else {
              if (Get.currentRoute == '/RideRequestScreen') {
                Get.back();
              }
            }
          } else if (message.data['action'] == 'identity_image_approved' ||
              message.data['action'] == 'identity_image_rejected') {
            Get.find<ProfileController>().getProfileInfo();
          } else if (message.data['action'] == 'level_up') {
            _whenDriverLevelUp(message);
          } else if (message.data['action'] == "withdraw_request_rejected" ||
              message.data['action'] == "withdraw_request_approved") {
            Get.find<ProfileController>().getProfileInfo();
            Get.find<WalletController>().getWithdrawPendingList(1);
          } else if (message.data['action'] == "withdraw_request_settled") {
            Get.find<ProfileController>().getProfileInfo();
            Get.find<WalletController>().getWithdrawSettledList(1);
          } else if (message.data['action'] == "admin_collected_cash") {
            Get.find<ProfileController>().getProfileInfo();
            Get.find<WalletController>().getPayableHistoryList(1);
          } else if (message.data['action'] == 'parcel_returned') {
            if (Get.isDialogOpen ?? false) {
              Get.back();
            }
            Get.find<RideController>().getOngoingParcelList();
            Get.find<RideController>().getRideDetails(message.data['ride_request_id']);
            Get.bottomSheet(ReceiptConfirmationBottomsheet());
          } else if (message.data['action'] == 'parcel_canceled' || message.data['action'] == 'trip_canceled') {
            // Close overlay if showing (app might be in background with overlay visible)
            if (GetPlatform.isAndroid) {
              try {
                OverlayHelper.hideOverlay();
                if (kDebugMode) {
                  print('NotificationHelper: Closing overlay due to trip/parcel cancellation');
                }
              } catch (e) {
                if (kDebugMode) {
                  print('NotificationHelper: Error closing overlay on cancel: $e');
                }
              }
            }
            Get.offAll(const DashboardScreen());
          } else if (message.data['action'] == 'referral_reward_received') {
            Get.find<ReferAndEarnController>().getEarningHistoryList(1);
            Get.find<ProfileController>().getProfileInfo();
          } else if (message.data['action'] == 'admin_message') {
            Get.find<HelpAndSupportController>().getConversation(message.data['type'], 1);
          } else if (message.data['action'] == 'safety_problem_resolved') {
            Get.find<SafetyAlertController>().getSafetyAlertDetails(message.data['ride_request_id']);
          }

          ///If web socket Not connected
        } else {
          if (message.data['action'] == "bid_accepted") {
            ///Bid Ride Accepted in this case....
            _whenCustomerBidAccept(message);
          } else if (checkContainsAction(message.data['action'])) {
            Get.find<ProfileController>().getProfileInfo().then((value) {
              if (value.statusCode == 200) {
                Get.find<RiderMapController>().setRideCurrentState(RideState.initial);
                Get.offAll(() => const DashboardScreen());
              }
            });
          } else if (message.data['action'] == "customer_rejected_bid") {
            if ((Get.find<RideController>().ongoingTrip ?? []).isEmpty) {
              Get.offAll(() => const DashboardScreen());
            } else {
              if (Get.currentRoute == '/RideRequestScreen') {
                Get.back();
              }
            }
          } else if (message.data['action'] == 'identity_image_approved' ||
              message.data['action'] == 'identity_image_rejected') {
            Get.find<ProfileController>().getProfileInfo();
          } else if (message.data['action'] == 'level_up') {
            _whenDriverLevelUp(message);
          } else if (message.data['action'] == "withdraw_request_rejected" ||
              message.data['action'] == "withdraw_request_approved") {
            Get.find<ProfileController>().getProfileInfo();
            Get.find<WalletController>().getWithdrawPendingList(1);
          } else if (message.data['action'] == "withdraw_request_settled") {
            Get.find<ProfileController>().getProfileInfo();
            Get.find<WalletController>().getWithdrawSettledList(1);
          } else if (message.data['action'] == "admin_collected_cash") {
            Get.find<ProfileController>().getProfileInfo();
            Get.find<WalletController>().getPayableHistoryList(1);
          } else if (message.data['action'] == 'parcel_returned') {
            if (Get.isDialogOpen ?? false) {
              Get.back();
            }
            Get.find<RideController>().getOngoingParcelList();
            Get.find<RideController>().getRideDetails(message.data['ride_request_id']);
            Get.bottomSheet(ReceiptConfirmationBottomsheet());
          } else if (message.data['action'] == 'parcel_canceled' || message.data['action'] == 'trip_canceled') {
            // Close overlay if showing (app might be in background with overlay visible)
            if (GetPlatform.isAndroid) {
              try {
                OverlayHelper.hideOverlay();
                if (kDebugMode) {
                  print('NotificationHelper: Closing overlay due to trip/parcel cancellation');
                }
              } catch (e) {
                if (kDebugMode) {
                  print('NotificationHelper: Error closing overlay on cancel: $e');
                }
              }
            }
            Get.offAll(const DashboardScreen());
          } else if (message.data['action'] == 'referral_reward_received') {
            Get.find<ReferAndEarnController>().getEarningHistoryList(1);
            Get.find<ProfileController>().getProfileInfo();
          } else if (message.data['action'] == 'admin_message') {
            Get.find<HelpAndSupportController>().getConversation(message.data['type'], 1);
          } else if (message.data['action'] == 'safety_problem_resolved') {
            Get.find<SafetyAlertController>().getSafetyAlertDetails(message.data['ride_request_id']);
          }
        }

        ///checking which notification are not shown.
        // Exclude cancel notifications (customer_canceled_trip, another_driver_assigned, trip_canceled, parcel_canceled)
        // These should close overlay but not show notification
        if (!(message.data['action'] == "customer_canceled_trip" ||
            message.data['action'] == "another_driver_assigned" ||
            message.data['action'] == "trip_canceled" ||
            message.data['action'] == "parcel_canceled" ||
            message.data['type'] == 'maintenance_mode_on' ||
            message.data['type'] == 'maintenance_mode_off')) {
          if (message.data['status'] == '1') {
            NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin, true);
          }
        }
      }

      if (message.data['type'] == 'maintenance_mode_on' || message.data['type'] == 'maintenance_mode_off') {
        Get.find<SplashController>().getConfigData(reload: false);
      }

      if (message.data['action'] == 'parcel_amount_deducted') {
        _whenParcelAmountDeducted(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      customPrint('onOpenApp: ${message.data}');
      notificationToRoute(message.data);
    });
  }

  static Future<void> showNotification(RemoteMessage message, FlutterLocalNotificationsPlugin fln, bool data) async {
    final String? action = message.data['action'];

    if (kDebugMode) {
      print('NotificationHelper: showNotification called - action: $action');
    }

    // Check if we're in background isolate (Get.find will fail in background)
    bool isInBackground = false;
    try {
      // Try to access GetX - if this fails, we're in background isolate
      Get.find<SplashController>();
      isInBackground = false; // App is in foreground
      if (kDebugMode) {
        print('NotificationHelper: GetX available - app is in FOREGROUND');
      }
    } catch (e) {
      isInBackground = true; // App is in background (GetX not available)
      if (kDebugMode) {
        print('NotificationHelper: GetX not available - app is in BACKGROUND');
      }
    }

    // Handle cancel notifications (customer_canceled_trip, another_driver_assigned, trip_canceled, parcel_canceled)
    // Close overlay if showing, but don't show notification (cancel notifications are excluded from showing)
    if (GetPlatform.isAndroid &&
        (action == "customer_canceled_trip" ||
            action == "another_driver_assigned" ||
            action == "trip_canceled" ||
            action == "parcel_canceled")) {
      // Close overlay if showing (works in both foreground and background)
      if (kDebugMode) {
        print('NotificationHelper: Cancel notification received - closing overlay (no notification shown)');
      }
      try {
        await OverlayHelper.hideOverlay();
        if (kDebugMode) {
          print('NotificationHelper: Overlay closed successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('NotificationHelper: Error closing overlay: $e');
        }
      }
      // Don't show notification - just close overlay
      return;
    }

    // For new ride/parcel requests, only trigger overlay if app is in background
    // When app is in foreground, the in-app UI will be shown via _whenNewRequestFound
    if (GetPlatform.isAndroid && (action == "new_ride_request" || action == "new_parcel_request")) {
      if (kDebugMode) {
        print('NotificationHelper: New ride/parcel request detected - isInBackground: $isInBackground');
      }
      if (isInBackground) {
        // Only show overlay when app is in background
        if (kDebugMode) {
          print('NotificationHelper: App is in BACKGROUND - will show overlay');
        }
        await _showTripNotificationWithOverlay(message, fln);
        return;
      } else {
        // App is in foreground - just show notification, in-app UI will handle it
        if (kDebugMode) {
          print('NotificationHelper: App is in FOREGROUND, skipping overlay - in-app UI will show');
        }
        // Show regular notification
        String title = message.data['title'];
        String body = message.data['body'];
        final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'hexaride',
          'hexaride',
          priority: Priority.max,
          importance: Importance.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('notification'),
        );
        final NotificationDetails platformChannelSpecifics =
            NotificationDetails(android: androidPlatformChannelSpecifics);
        await fln.show(0, title, body, platformChannelSpecifics, payload: jsonEncode(message.data));
        return;
      }
    }

    String title = message.data['title'];
    String body = message.data['body'];
    String? orderID = message.data['order_id'];
    String? image = (message.data['image'] != null && message.data['image'].isNotEmpty)
        ? message.data['image'].startsWith('http')
            ? message.data['image']
            : '${AppConstants.baseUrl}/storage/app/public/notification/${message.data['image']}'
        : null;

    try {
      await showBigPictureNotificationHiddenLargeIcon(title, body, orderID, image, fln);
    } catch (e) {
      await showBigPictureNotificationHiddenLargeIcon(title, body, orderID, null, fln);
      customPrint('Failed to show notification: ${e.toString()}');
    }
  }

  /// Show trip notification and trigger overlay
  static Future<void> _showTripNotificationWithOverlay(
      RemoteMessage message, FlutterLocalNotificationsPlugin fln) async {
    final Map<String, dynamic> notificationData = message.data;
    final String title = notificationData['title'] ?? 'New trip request';
    final String body = notificationData['body'] ?? '';
    final String? rideRequestId = notificationData['ride_request_id'];

    // Show notification first (don't wait for trip details)
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'hexaride',
      'hexaride',
      priority: Priority.max,
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics, payload: jsonEncode(notificationData));

    // Trigger overlay with enriched data
    if (GetPlatform.isAndroid) {
      try {
        // Try to fetch trip details to enrich the overlay data
        Map<String, dynamic> enrichedData = Map<String, dynamic>.from(notificationData);

        if (rideRequestId != null && rideRequestId.isNotEmpty) {
          try {
            // Try to fetch trip details - works in both foreground and background
            if (kDebugMode) {
              print('NotificationHelper: Fetching trip details for ride_request_id: $rideRequestId');
            }
            final tripDetails = await _fetchTripDetailsForOverlay(rideRequestId);
            if (tripDetails != null) {
              // Enrich notification data with trip details
              final customer = tripDetails['customer'];
              if (customer != null) {
                final firstName = customer['first_name'] ?? '';
                final lastName = customer['last_name'] ?? '';
                enrichedData['user_name'] = '$firstName $lastName'.trim();
                enrichedData['customer_profile_image'] = customer['profile_image'] ?? '';
              }
              enrichedData['estimated_fare'] = tripDetails['estimated_fare']?.toString() ?? '';
              enrichedData['estimated_time'] = tripDetails['estimated_time']?.toString() ?? '';
              enrichedData['estimated_distance'] = tripDetails['estimated_distance']?.toString() ?? '';
              enrichedData['pickup_address'] = tripDetails['pickup_address'] ?? '';
              enrichedData['destination_address'] = tripDetails['destination_address'] ?? '';
              enrichedData['customer_avg_rating'] = tripDetails['customer_avg_rating']?.toString() ?? '';

              if (kDebugMode) {
                print('NotificationHelper: Enriched overlay data with trip details');
                print(
                    'NotificationHelper: Enriched data - user_name: ${enrichedData['user_name']}, estimated_fare: ${enrichedData['estimated_fare']}, pickup_address: ${enrichedData['pickup_address']}');
              }
            } else {
              if (kDebugMode) {
                print('NotificationHelper: Trip details fetch returned null - using basic notification data');
              }
            }
          } catch (e, stackTrace) {
            if (kDebugMode) {
              print('NotificationHelper: Failed to fetch trip details for overlay: $e');
              print('NotificationHelper: Stack trace: $stackTrace');
            }
            // Continue with basic notification data if fetch fails
          }
        } else {
          if (kDebugMode) {
            print('NotificationHelper: No ride_request_id found - using basic notification data');
          }
        }

        if (kDebugMode) {
          print(
              'NotificationHelper: Sending data to overlay - user_name: ${enrichedData['user_name']}, estimated_fare: ${enrichedData['estimated_fare']}');
        }
        await OverlayHelper.showIncomingTripOverlay(enrichedData);
      } catch (e) {
        if (kDebugMode) {
          print('NotificationHelper: Failed to show overlay (might be background): $e');
        }
        // The overlay helper will store it for showing when app comes to foreground
      }
    }
  }

  static Future<void> showTextNotification(
      String title, String body, String orderID, String action, FlutterLocalNotificationsPlugin fln) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'hexaride',
      'hexaride',
      playSound: true,
      importance: Importance.max,
      priority: Priority.max,
      sound: RawResourceAndroidNotificationSound('notification'),
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics, payload: action);
  }

  static Future<void> showBigTextNotification(
      String title, String body, String orderID, String action, FlutterLocalNotificationsPlugin fln) async {
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'hexaride',
      'hexaride',
      importance: Importance.max,
      styleInformation: bigTextStyleInformation,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics, payload: action);
  }

  static Future<void> showBigPictureNotificationHiddenLargeIcon(
      String title, String body, String? orderID, String? image, FlutterLocalNotificationsPlugin fln) async {
    String? largeIconPath;
    String? bigPicturePath;
    BigPictureStyleInformation? bigPictureStyleInformation;
    BigTextStyleInformation? bigTextStyleInformation;
    if (image != null && !GetPlatform.isWeb) {
      largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
      bigPicturePath = largeIconPath;
      bigPictureStyleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(bigPicturePath),
        hideExpandedLargeIcon: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: body,
        htmlFormatSummaryText: true,
      );
    } else {
      bigTextStyleInformation = BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
      );
    }
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'hexaride',
      'hexaride',
      priority: Priority.max,
      importance: Importance.max,
      playSound: true,
      largeIcon: largeIconPath != null ? FilePathAndroidBitmap(largeIconPath) : null,
      styleInformation: largeIconPath != null ? bigPictureStyleInformation : bigTextStyleInformation,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics, payload: orderID);
  }

  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static Future<void> notificationToRoute(Map<String, dynamic> data,
      {bool formSplash = false, String? userName}) async {
    if (data['action'] == "new_message") {
      Get.find<ChatController>().getConversation(data['type'], 1);
      _toRoute(
          formSplash,
          MessageScreen(
              channelId: data['type'], tripId: data['ride_request_id'], userName: userName ?? data['user_name']));
    } else if (data['action'] == "new_ride_request" || data['action'] == "new_parcel_request") {
      Get.find<RideController>().ongoingTripList().then((value) {
        if ((Get.find<RideController>().ongoingTrip ?? []).isEmpty) {
          Get.find<RideController>().getRideDetailBeforeAccept(data['ride_request_id']).then((value) {
            if (value.statusCode == 200) {
              Get.find<RideController>().getPendingRideRequestList(1, limit: 100);
              Get.find<RideController>().setRideId(data['ride_request_id']);
              Get.find<RiderMapController>().getPickupToDestinationPolyline();
              Get.find<RiderMapController>().setRideCurrentState(RideState.pending);
              Get.find<RideController>().updateRoute(false, notify: true);
              if (formSplash && data['type'] == "parcel") {
                Get.find<RideController>().getOngoingParcelList();
              }
              _toRoute(formSplash, const MapScreen());
            }
          });
        } else {
          if (Get.currentRoute != '/RideRequestScreen') {
            Get.to(() => RideRequestScreen());
          } else {
            Get.find<RideController>().getPendingRideRequestList(1, limit: 100);
          }
        }
      });
    } else if (data['action'] == "bid_accepted") {
      ///Bid Ride Accepted in this case....
      Get.find<RideController>().getRideDetails(data['ride_request_id']).then((value) {
        if (value.statusCode == 200) {
          Get.find<RiderMapController>().setRideCurrentState(RideState.outForPickup);
          Get.find<RideController>().updateRoute(false, notify: true);
          _toRoute(formSplash, const MapScreen());
        }
      });
    } else if (data['action'] == "payment_successful" && data['type'] == "ride_request") {
      Get.offAll(() => const DashboardScreen());
      Get.find<BottomMenuController>().setTabIndex(3);
    } else if (data['action'] == "payment_successful" && data['type'] == "parcel") {
      Get.offAll(() => const DashboardScreen());
      Get.find<BottomMenuController>().setTabIndex(3);
    } else if (data['action'] == "customer_canceled_trip" || data['action'] == "another_driver_assigned") {
      Get.find<RideController>().getPendingRideRequestList(1).then((value) {
        Get.find<RideController>().tripDetail = null;
        if (value.statusCode == 200) {
          Get.find<RiderMapController>().setRideCurrentState(RideState.initial);
          Get.offAll(() => const DashboardScreen());
        }
      });
    } else if (checkContainsAction(data['action'])) {
      Get.find<ProfileController>().getProfileInfo().then((value) {
        if (value.statusCode == 200) {
          Get.find<RiderMapController>().setRideCurrentState(RideState.initial);
          Get.find<ProfileController>().setProfileTypeIndex(2, isUpdate: true);
          _toRoute(formSplash, const ProfileScreen());
        }
      });
    } else if (data['action'] == "withdraw_request_rejected" ||
        data['action'] == "withdraw_request_approved" ||
        data['action'] == "admin_collected_cash" ||
        data['action'] == "withdraw_request_reversed") {
      Get.offAll(() => const DashboardScreen());
      Get.find<BottomMenuController>().setTabIndex(3);
    } else if (data['action'] == "withdraw_request_settled") {
      Get.offAll(() => const DashboardScreen());
      Get.find<BottomMenuController>().setTabIndex(3);
      Get.find<WalletController>().setSelectedHistoryIndex(1, true);
    } else if (data['action'] == "customer_rejected_bid") {
      Get.offAll(() => const DashboardScreen());
    } else if (data['action'] == "review_from_customer") {
      _toRoute(formSplash, const ReviewScreen());
    } else if (data['action'] == 'identity_image_approved' || data['action'] == 'identity_image_rejected') {
      Get.find<ProfileController>().getProfileInfo().then((value) {
        _toRoute(formSplash, ProfileEditScreen(profileInfo: Get.find<ProfileController>().profileInfo!));
      });
    } else if (data['action'] == 'level_up') {
      Get.find<ProfileController>().getProfileLevelInfo();

      if (formSplash) {
        _toRoute(formSplash, const DashboardScreen());
      }

      showDialog(
        context: Get.context!,
        barrierDismissible: false,
        builder: (_) => LevelCongratulationsDialogWidget(
          levelName: data['next_level'],
          rewardType: data['reward_type'],
          reward: data['reward_amount'],
        ),
      );
    } else if (data['action'] == 'privacy_policy_updated') {
      Get.find<SplashController>().getConfigData().then((value) {
        _toRoute(
            formSplash,
            PolicyViewerScreen(
              htmlType: HtmlType.privacyPolicy,
              image: Get.find<SplashController>().config?.privacyPolicy?.image ?? '',
            ));
      });
    } else if (data['action'] == 'legal_updated') {
      Get.find<SplashController>().getConfigData().then((value) {
        _toRoute(
            formSplash,
            PolicyViewerScreen(
                htmlType: HtmlType.legal, image: Get.find<SplashController>().config?.legal?.image ?? ''));
      });
    } else if (data['action'] == 'terms_and_conditions_updated') {
      Get.find<SplashController>().getConfigData().then((value) {
        _toRoute(
            formSplash,
            PolicyViewerScreen(
                htmlType: HtmlType.termsAndConditions,
                image: Get.find<SplashController>().config?.termsAndConditions?.image ?? ''));
      });
    } else if (data['action'] == 'referral_reward_received') {
      _toRoute(formSplash, const ReferAndEarnScreen());
    } else if (data['action'] == 'parcel_amount_deducted') {
      _toRoute(formSplash, TripDetails(tripId: data['ride_request_id']));
    } else if (data['action'] == 'refund_accepted') {
      _toRoute(formSplash, TripDetails(tripId: data['ride_request_id']));
    } else if (data['action'] == 'refund_denied') {
      _toRoute(formSplash, TripDetails(tripId: data['ride_request_id']));
    } else if (data['action'] == 'parcel_amount_debited') {
      Get.offAll(() => const DashboardScreen());
      Get.find<BottomMenuController>().setTabIndex(3);
    } else if (data['action'] == 'tips_from_customer') {
      _toRoute(formSplash, TripDetails(tripId: data['ride_request_id']));
    } else if (data['action'] == 'admin_message') {
      Get.find<HelpAndSupportController>().getPredefineFaqList();
      Get.find<HelpAndSupportController>().createChannel(fromSplash: formSplash);
    } else if (data['action'] == 'safety_problem_resolved' && data['type'] == 'safety_alert') {
      Get.find<RideController>().getRideDetails(data['ride_request_id']).then((value) {
        if (value.statusCode == 200) {
          if (Get.find<RideController>().tripDetail?.currentStatus == 'ongoing') {
            if (Get.currentRoute != '/MapScreen') {
              Get.find<RiderMapController>().setRideCurrentState(RideState.ongoing);
              _toRoute(formSplash, const MapScreen());
            }
          } else {
            if (Get.currentRoute != '/TripDetails') {
              _toRoute(formSplash, TripDetails(tripId: data['ride_request_id']));
            }
          }
        }
      });
    } else if (data['action'] == 'parcel_return_penalty') {
      _toRoute(formSplash, TripDetails(tripId: data['ride_request_id']));
    } else {
      Get.offAll(() => const DashboardScreen());
    }
  }

  static Future _toRoute(bool formSplash, Widget page) async {
    if (formSplash) {
      await Get.offAll(() => page);
    } else {
      await Get.to(() => page);
    }
  }

  /// Fetch trip details for overlay - works in both foreground and background isolates
  static Future<Map<String, dynamic>?> _fetchTripDetailsForOverlay(String rideRequestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.token) ?? '';
      final languageCode = prefs.getString(AppConstants.languageCode) ?? 'en';
      final zoneId = prefs.getString(AppConstants.zoneId) ?? '';

      if (token.isEmpty) {
        if (kDebugMode) {
          print('NotificationHelper: No token available for API call');
        }
        return null;
      }

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        AppConstants.localization: languageCode,
        'zoneId': zoneId,
        'Authorization': 'Bearer $token',
      };

      final url = '${AppConstants.baseUrl}${AppConstants.tripDetails}$rideRequestId?type=overview';

      if (kDebugMode) {
        print('NotificationHelper: Fetching trip details from: $url');
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null) {
          if (kDebugMode) {
            print('NotificationHelper: Successfully fetched trip details');
          }
          return responseData['data'] as Map<String, dynamic>;
        }
      } else {
        if (kDebugMode) {
          print('NotificationHelper: Failed to fetch trip details - status: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationHelper: Error fetching trip details: $e');
      }
    }
    return null;
  }

  /// Open app and show trip details when overlay is tapped/opened
  /// Similar to _whenNewRequestFound but can be called with just ride_request_id
  /// This method closes the overlay and navigates to MapScreen with trip details
  static Future<void> openAppAndShowTrip(String rideRequestId) async {
    try {
      if (kDebugMode) {
        print('NotificationHelper: Opening app and showing trip: $rideRequestId');
      }

      // Close overlay first
      if (GetPlatform.isAndroid) {
        try {
          await OverlayHelper.hideOverlay();
        } catch (e) {
          if (kDebugMode) {
            print('NotificationHelper: Error closing overlay: $e');
          }
        }
      }

      // Check if GetX is available (app is running)
      try {
        Get.find<RideController>();
      } catch (e) {
        if (kDebugMode) {
          print('NotificationHelper: App not running, cannot show trip');
        }
        return;
      }

      // Same flow as _whenNewRequestFound
      Get.find<RideController>().ongoingTripList().then((value) {
        if ((Get.find<RideController>().ongoingTrip ?? []).isEmpty) {
          Get.find<RideController>().getPendingRideRequestList(1);
          AudioPlayer audio = AudioPlayer();
          audio.play(AssetSource('notification.wav'));
          Get.find<RideController>().setRideId(rideRequestId);
          Get.find<RideController>().getRideDetailBeforeAccept(rideRequestId).then((value) {
            if (value.statusCode == 200) {
              Get.find<RiderMapController>().getPickupToDestinationPolyline();
              Get.find<RiderMapController>().setRideCurrentState(RideState.pending);
              Get.find<RideController>().updateRoute(false, notify: true);
              Get.to(() => const MapScreen());
            }
          });
        } else {
          if (Get.currentRoute == '/MapScreen') {
            Get.find<RideController>().getPendingRideRequestList(1, limit: 100);
          } else {
            Get.to(() => RideRequestScreen());
          }
        }
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('NotificationHelper: Error opening app and showing trip: $e');
        print('NotificationHelper: Stack trace: $stackTrace');
      }
    }
  }
}

@pragma('vm:entry-point')
Future<dynamic> myBackgroundMessageHandler(RemoteMessage remoteMessage) async {
  customPrint('onBackground: ${remoteMessage.data}');

  // Initialize notifications for background
  AndroidInitializationSettings androidInitialize = const AndroidInitializationSettings('notification_icon');
  var iOSInitialize = const DarwinInitializationSettings();
  var initializationsSettings = InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(initializationsSettings);

  // Show notification (this will also trigger overlay via broadcast)
  await NotificationHelper.showNotification(remoteMessage, flutterLocalNotificationsPlugin, true);
}

Future<dynamic> myBackgroundMessageReceiver(NotificationResponse response) async {
  customPrint('onBackgroundClicked: ${response.payload}');
}

bool checkContainsAction(String action) {
  List<String> actions = [
    'vehicle_request_approved',
    'vehicle_update_denied',
    'vehicle_update_approved',
    'vehicle_request_denied'
  ];
  if (actions.contains(action)) {
    return true;
  } else {
    return false;
  }
}

void _whenNewRequestFound(RemoteMessage message) {
  Get.find<RideController>().ongoingTripList().then((value) {
    if ((Get.find<RideController>().ongoingTrip ?? []).isEmpty) {
      Get.find<RideController>().getPendingRideRequestList(1);
      AudioPlayer audio = AudioPlayer();
      audio.play(AssetSource('notification.wav'));
      Get.find<RideController>().setRideId(message.data['ride_request_id']);
      Get.find<RideController>().getRideDetailBeforeAccept(message.data['ride_request_id']).then((value) {
        if (value.statusCode == 200) {
          Get.find<RiderMapController>().getPickupToDestinationPolyline();
          Get.find<RiderMapController>().setRideCurrentState(RideState.pending);
          Get.find<RideController>().updateRoute(false, notify: true);
          Get.to(() => const MapScreen());
        }
      });
    } else {
      if (Get.currentRoute == '/MapScreen') {
        Get.find<RideController>().getPendingRideRequestList(1, limit: 100);
      } else {
        Get.to(() => const RideRequestScreen());
      }
    }
  });
}

void _whenRideComplete(RemoteMessage message) {
  Get.find<SafetyAlertController>().cancelDriverNeedSafetyStream();
  Get.find<RideController>().getRideDetails(message.data['ride_request_id']).then((value) {
    if (value.statusCode == 200) {
      Get.find<RideController>().getFinalFare(message.data['ride_request_id']).then((value) {
        if (value.statusCode == 200) {
          Get.find<RiderMapController>().setRideCurrentState(RideState.initial);
          Get.to(() => const PaymentReceivedScreen());
        }
      });
    }
  });
}

void _whenCustomerBidAccept(RemoteMessage message) {
  Get.find<RideController>().ongoingTripList().then((value) {
    if ((Get.find<RideController>().ongoingTrip ?? []).length <= 1) {
      Get.find<RideController>().getRideDetails(message.data['ride_request_id']).then((value) {
        if (value.statusCode == 200) {
          Get.find<RiderMapController>().setRideCurrentState(RideState.outForPickup);
          Get.find<RideController>().updateRoute(false, notify: true);
          Get.to(() => const MapScreen());
        }
      });
    } else {
      if (Get.currentRoute == '/RideRequestScreen') {
        Get.back();
      }
    }
  });
}

void _whenRidePaymentSuccess(RemoteMessage message) {
  Get.find<RideController>().ongoingTripList().then((value) {
    if ((Get.find<RideController>().ongoingTrip ?? []).isEmpty) {
      Get.find<RideController>().getRideDetails(message.data['ride_request_id']).then((value) {
        if (value.statusCode == 200) {
          if (Get.find<SplashController>().config!.reviewStatus!) {
            Get.offAll(() => ReviewThisCustomerScreen(tripId: message.data['ride_request_id']));
          } else {
            Get.offAll(() => const DashboardScreen());
          }
        }
      });
    } else {
      Get.offAll(() => const RideListScreen());
    }
  });
}

void _whenCustomerCancelTrip(RemoteMessage message) {
  if (Get.find<RideController>().tripDetail?.id == message.data['ride_request_id']) {
    Get.find<SafetyAlertController>().cancelDriverNeedSafetyStream();
    Get.find<RideController>().tripDetail = null;
    Get.find<RideController>().getPendingRideRequestList(1).then((value) {
      if (value.statusCode == 200) {
        Get.find<RiderMapController>().setRideCurrentState(RideState.initial);
        Get.offAll(() => const DashboardScreen());
      }
    });
  } else {
    Get.find<RideController>().ongoingTripList();
    Get.find<RideController>().getPendingRideRequestList(1, limit: 100);
  }
}

void _whenDriverLevelUp(RemoteMessage message) {
  Get.find<ProfileController>().getProfileLevelInfo();
  showDialog(
    context: Get.context!,
    barrierDismissible: false,
    builder: (_) => LevelCongratulationsDialogWidget(
      levelName: message.data['next_level'],
      rewardType: message.data['reward_type'],
      reward: message.data['reward_amount'],
    ),
  );
}

void _whenParcelAmountDeducted(RemoteMessage message) {
  final RideController rideController = Get.find<RideController>();
  bool isShowBottomSheet =
      ((rideController.ongoingRideList?.length ?? 0) == 0) && ((rideController.parcelListModel?.totalSize ?? 0) == 0);

  if (isShowBottomSheet) {
    showModalBottomSheet(
        context: Get.context!,
        builder: (ctx) => RefundAlertBottomSheet(
              title: message.data['title'],
              description: message.data['body'],
              tripId: message.data['ride_request_id'],
            ));
  } else {
    /// Add the refund data to show dialog after complete ongoing ride
    Get.find<SplashController>().addLastReFoundData(message.data);
  }
}
