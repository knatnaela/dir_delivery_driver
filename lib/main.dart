import 'package:dir_delivery_driver/helper/notification_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:dir_delivery_driver/util/dimensions.dart';
import 'package:dir_delivery_driver/util/images.dart';
import 'package:dir_delivery_driver/features/map/screens/map_screen.dart';
import 'package:dir_delivery_driver/features/ride/controllers/ride_controller.dart';
import 'package:dir_delivery_driver/features/splash/controllers/splash_controller.dart';
import 'package:dir_delivery_driver/helper/di_container.dart' as di;
import 'package:dir_delivery_driver/helper/route_helper.dart';
import 'package:dir_delivery_driver/localization/localization_controller.dart';
import 'package:dir_delivery_driver/localization/messages.dart';
import 'package:dir_delivery_driver/theme/dark_theme.dart';
import 'package:dir_delivery_driver/theme/light_theme.dart';
import 'package:dir_delivery_driver/theme/theme_controller.dart';
import 'package:dir_delivery_driver/util/app_constants.dart';
import 'package:dir_delivery_driver/features/map/controllers/map_controller.dart' as map_ctrl;
import 'package:dir_delivery_driver/features/overlay/widgets/incoming_trip_overlay_widget.dart';
import 'package:dir_delivery_driver/helper/isolate_manager.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Overlay entry point for system_alert_window
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Material(child: IncomingTripOverlayWidget()),
  ));
}

Future<void> main() async {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark, // dark text for status bar
        statusBarColor: Colors.transparent),
  );

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  Map<String, Map<String, String>> languages = await di.init();

  final RemoteMessage? remoteMessage = await FirebaseMessaging.instance.getInitialMessage();

  await NotificationHelper.initialize(flutterLocalNotificationsPlugin);

  FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);

  // Set up isolate communication for overlay to send messages to main app
  try {
    ReceivePort overlayReceivePort = ReceivePort();
    IsolateManager.registerPortWithName(overlayReceivePort.sendPort);
    overlayReceivePort.listen((message) {
      if (kDebugMode) {
        print('Main app: Received message from overlay isolate: $message');
      }
      try {
        Map<String, dynamic> data;
        if (message is String) {
          data = jsonDecode(message);
        } else if (message is Map) {
          data = Map<String, dynamic>.from(message);
        } else {
          data = jsonDecode(message.toString());
        }

        if (data['action'] == 'open_trip_from_overlay') {
          final rideRequestId = data['ride_request_id'];
          if (rideRequestId != null) {
            if (kDebugMode) {
              print('Main app: Opening trip from overlay isolate: $rideRequestId');
            }
            // Handle opening trip
            _handleOpenTripFromOverlay(rideRequestId);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Main app: Error handling overlay isolate message: $e');
        }
      }
    });
    if (kDebugMode) {
      print('Main app: Isolate communication set up successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Main app: Error setting up isolate communication (non-critical): $e');
    }
    // Don't fail app startup if isolate communication fails - overlay can still use overlayListener
  }

  // Check for ride_request_id from Intent (when app is brought to front from overlay)
  try {
    const platform = MethodChannel('com.dir_delivery_driver/app_lifecycle');
    final rideRequestIdFromIntent = await platform.invokeMethod<String>('getRideRequestFromIntent');
    if (rideRequestIdFromIntent != null && rideRequestIdFromIntent.isNotEmpty) {
      if (kDebugMode) {
        print('Main app: Found ride_request_id from Intent: $rideRequestIdFromIntent');
      }
      // Wait a bit for app to initialize
      Future.delayed(const Duration(milliseconds: 500), () {
        NotificationHelper.openAppAndShowTrip(rideRequestIdFromIntent);
      });
    }
  } catch (e) {
    if (kDebugMode) {
      print('Main app: No ride_request_id from Intent or error: $e');
    }
  }

  // Listen for messages from overlay via overlayListener (for backward compatibility)
  SystemAlertWindow.overlayListener.listen((event) async {
    if (kDebugMode) {
      print('Main app: Received overlay message: $event');
    }
    try {
      Map<String, dynamic> data;
      if (event is String) {
        data = jsonDecode(event);
      } else if (event is Map) {
        data = Map<String, dynamic>.from(event);
      } else {
        data = jsonDecode(event.toString());
      }

      if (kDebugMode) {
        print('Main app: Parsed overlay message action: ${data['action']}');
      }

      if (data['action'] == 'close_overlay') {
        // Close overlay from main app (with prefMode as shown in example)
        if (kDebugMode) {
          print('Main app: Closing overlay...');
        }
        SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY).then((_) {
          if (kDebugMode) {
            print('Main app: Overlay closed successfully');
          }
        }).catchError((e) {
          if (kDebugMode) {
            print('Main app: Error closing overlay: $e');
          }
        });
      } else if (data['action'] == 'open_trip_from_overlay') {
        // Handle opening trip from overlay (when user taps to view details)
        final rideRequestId = data['ride_request_id'];

        if (rideRequestId != null) {
          if (kDebugMode) {
            print('Main app: Opening trip from overlay: $rideRequestId');
          }

          // Close overlay first (in case it's still open)
          try {
            await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
          } catch (e) {
            if (kDebugMode) {
              print('Main app: Error closing overlay: $e');
            }
          }

          // Bring app to foreground using MethodChannel
          try {
            const platform = MethodChannel('com.dir_delivery_driver/app_lifecycle');
            await platform.invokeMethod('bringToFrontWithRideRequest', {'ride_request_id': rideRequestId});
            if (kDebugMode) {
              print('Main app: Called bringToFrontWithRideRequest - ride_request_id: $rideRequestId');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Main app: Could not bring app to front: $e');
            }
          }

          // Wait a bit for app to come to foreground and Intent to be processed
          await Future.delayed(const Duration(milliseconds: 800));

          // Check if we got ride_request_id from Intent (if app was brought to front)
          try {
            const platform = MethodChannel('com.dir_delivery_driver/app_lifecycle');
            final rideRequestIdFromIntent = await platform.invokeMethod<String>('getRideRequestFromIntent');
            if (rideRequestIdFromIntent != null && rideRequestIdFromIntent.isNotEmpty) {
              if (kDebugMode) {
                print('Main app: Found ride_request_id from Intent, opening trip: $rideRequestIdFromIntent');
              }
              await NotificationHelper.openAppAndShowTrip(rideRequestIdFromIntent);
            } else {
              // If no Intent data, use the ride_request_id from message
              if (kDebugMode) {
                print('Main app: No Intent data, using ride_request_id from message: $rideRequestId');
              }
              await NotificationHelper.openAppAndShowTrip(rideRequestId);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Main app: Error checking Intent, using ride_request_id from message: $e');
            }
            await NotificationHelper.openAppAndShowTrip(rideRequestId);
          }
        }
      } else if (data['action'] == 'accept_trip') {
        // Handle accept trip action from overlay
        final rideRequestId = data['ride_request_id'];
        final type = data['type'] ?? 'ride_request';
        final parcelWeight = data['parcel_weight'] ?? '0';

        if (rideRequestId != null) {
          if (kDebugMode) {
            print('Main app: Accepting trip $rideRequestId, type: $type');
          }

          // Close overlay first (in case it's still open)
          SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY).catchError((e) {
            if (kDebugMode) {
              print('Main app: Error closing overlay: $e');
            }
            return false;
          });

          // Bring app to foreground first
          try {
            const platform = MethodChannel('com.dir_delivery_driver/app_lifecycle');
            await platform.invokeMethod('bringToFront');
          } catch (e) {
            if (kDebugMode) {
              print('Main app: Could not bring app to front: $e');
            }
          }

          // Accept the trip using RideController
          Get.find<RideController>()
              .tripAcceptOrRejected(
            rideRequestId,
            'accepted',
            type == 'parcel_request' ? 'parcel' : type,
            parcelWeight,
            showSuccess: false, // Don't show success snackbar since we're navigating
          )
              .then((response) async {
            if (response.statusCode == 200) {
              if (kDebugMode) {
                print('Main app: Trip accepted successfully, navigating to MapScreen');
              }

              // Get ride details and navigate to MapScreen
              Get.find<RideController>().ongoingTripList().then((value) {
                if ((Get.find<RideController>().ongoingTrip ?? []).isEmpty) {
                  Get.find<RideController>().getRideDetailBeforeAccept(rideRequestId).then((value) {
                    if (value.statusCode == 200) {
                      Get.find<RideController>().getPendingRideRequestList(1, limit: 100);
                      Get.find<RideController>().setRideId(rideRequestId);
                      Get.find<map_ctrl.RiderMapController>().getPickupToDestinationPolyline();

                      // Set appropriate ride state based on type
                      if (type == 'parcel_request') {
                        Get.find<RideController>().getOngoingParcelList();
                      }

                      // Determine ride state - if scheduled, set to accepted, otherwise outForPickup
                      // We'll check this after getting ride details
                      Get.find<RideController>().getRideDetails(rideRequestId).then((detailsResponse) {
                        if (detailsResponse.statusCode == 200) {
                          final tripDetail = Get.find<RideController>().tripDetail;
                          if (tripDetail?.type == AppConstants.scheduleRequest) {
                            Get.find<map_ctrl.RiderMapController>().setRideCurrentState(map_ctrl.RideState.accepted);
                          } else {
                            Get.find<map_ctrl.RiderMapController>()
                                .setRideCurrentState(map_ctrl.RideState.outForPickup);
                          }
                        } else {
                          // Default to outForPickup if we can't determine
                          Get.find<map_ctrl.RiderMapController>().setRideCurrentState(map_ctrl.RideState.outForPickup);
                        }

                        Get.find<RideController>().updateRoute(false, notify: true);
                        Get.to(() => const MapScreen());
                      });
                    }
                  });
                } else {
                  // Already have ongoing trips, just refresh pending list
                  Get.find<RideController>().getPendingRideRequestList(1, limit: 100);
                  Get.to(() => const MapScreen());
                }
              });
            } else {
              if (kDebugMode) {
                print('Main app: Failed to accept trip - status: ${response.statusCode}');
              }
            }
          }).catchError((e) {
            if (kDebugMode) {
              print('Main app: Error accepting trip: $e');
            }
          });
        }
      } else if (data['action'] == 'reject_trip') {
        // Handle reject trip action from overlay
        final rideRequestId = data['ride_request_id'];
        final type = data['type'] ?? 'ride_request';
        final parcelWeight = data['parcel_weight'] ?? '0';

        if (rideRequestId != null) {
          if (kDebugMode) {
            print('Main app: Rejecting trip $rideRequestId, type: $type');
          }

          // Close overlay first (in case it's still open)
          SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY).catchError((e) {
            if (kDebugMode) {
              print('Main app: Error closing overlay: $e');
            }
            return false;
          });

          // Reject the trip using RideController
          Get.find<RideController>()
              .tripAcceptOrRejected(
            rideRequestId,
            'rejected',
            type == 'parcel_request' ? 'parcel' : type,
            parcelWeight,
          )
              .then((response) {
            if (response.statusCode == 200) {
              if (kDebugMode) {
                print('Main app: Trip rejected successfully');
              }
              // Refresh pending ride list
              Get.find<RideController>().getPendingRideRequestList(1, limit: 100);
            } else {
              if (kDebugMode) {
                print('Main app: Failed to reject trip - status: ${response.statusCode}');
              }
            }
          }).catchError((e) {
            if (kDebugMode) {
              print('Main app: Error rejecting trip: $e');
            }
          });
        }
      } else if (data['action'] == 'open_trip') {
        // Legacy handler - kept for backward compatibility
        final rideRequestId = data['ride_request_id'];
        if (rideRequestId != null) {
          if (kDebugMode) {
            print('Main app: Opening trip $rideRequestId (legacy handler)');
          }
          NotificationHelper.notificationToRoute({
            'action': 'new_ride_request',
            'ride_request_id': rideRequestId,
          });
        }
      } else if (data['action'] == 'reject') {
        // Legacy handler - kept for backward compatibility
        if (kDebugMode) {
          print('Main app: Trip rejected (legacy handler)');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Main app: Error handling overlay message: $e');
        print('Main app: Stack trace: $stackTrace');
      }
    }
  });

  runApp(MyApp(languages: languages, notificationData: remoteMessage?.data));
}

/// Handle opening trip from overlay isolate
Future<void> _handleOpenTripFromOverlay(String rideRequestId) async {
  try {
    if (kDebugMode) {
      print('Main app: Handling open trip from overlay: $rideRequestId');
    }

    // Close overlay first (in case it's still open)
    try {
      await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
    } catch (e) {
      if (kDebugMode) {
        print('Main app: Error closing overlay: $e');
      }
    }

    // Bring app to foreground using MethodChannel
    try {
      const platform = MethodChannel('com.dir_delivery_driver/app_lifecycle');
      await platform.invokeMethod('bringToFrontWithRideRequest', {'ride_request_id': rideRequestId});
      if (kDebugMode) {
        print('Main app: Called bringToFrontWithRideRequest - ride_request_id: $rideRequestId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Main app: Could not bring app to front: $e');
      }
    }

    // Wait a bit for app to come to foreground and Intent to be processed
    await Future.delayed(const Duration(milliseconds: 800));

    // Check if we got ride_request_id from Intent (if app was brought to front)
    try {
      const platform = MethodChannel('com.dir_delivery_driver/app_lifecycle');
      final rideRequestIdFromIntent = await platform.invokeMethod<String>('getRideRequestFromIntent');
      if (rideRequestIdFromIntent != null && rideRequestIdFromIntent.isNotEmpty) {
        if (kDebugMode) {
          print('Main app: Found ride_request_id from Intent, opening trip: $rideRequestIdFromIntent');
        }
        await NotificationHelper.openAppAndShowTrip(rideRequestIdFromIntent);
      } else {
        // If no Intent data, use the ride_request_id from message
        if (kDebugMode) {
          print('Main app: No Intent data, using ride_request_id from message: $rideRequestId');
        }
        await NotificationHelper.openAppAndShowTrip(rideRequestId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Main app: Error checking Intent, using ride_request_id from message: $e');
      }
      await NotificationHelper.openAppAndShowTrip(rideRequestId);
    }
  } catch (e) {
    if (kDebugMode) {
      print('Main app: Error in _handleOpenTripFromOverlay: $e');
    }
  }
}

class MyApp extends StatefulWidget {
  final Map<String, Map<String, String>> languages;
  final Map<String, dynamic>? notificationData;
  const MyApp({super.key, required this.languages, this.notificationData});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - check for ride_request_id from Intent
      _checkForRideRequestFromIntent();
    }
  }

  Future<void> _checkForRideRequestFromIntent() async {
    try {
      const platform = MethodChannel('com.dir_delivery_driver/app_lifecycle');
      final rideRequestIdFromIntent = await platform.invokeMethod<String>('getRideRequestFromIntent');
      if (rideRequestIdFromIntent != null && rideRequestIdFromIntent.isNotEmpty) {
        if (kDebugMode) {
          print('MyApp: Found ride_request_id from Intent when app resumed: $rideRequestIdFromIntent');
        }
        // Wait a bit for app to fully initialize
        Future.delayed(const Duration(milliseconds: 500), () {
          NotificationHelper.openAppAndShowTrip(rideRequestIdFromIntent);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyApp: Error checking Intent when app resumed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Get.isDarkMode ? const Color(0xFF053B35) : const Color(0xFF00A08D),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark));
    if (GetPlatform.isWeb) {
      Get.find<SplashController>().initSharedData();
    }

    return GetBuilder<ThemeController>(builder: (themeController) {
      return GetBuilder<LocalizationController>(builder: (localizeController) {
        return GetBuilder<SplashController>(builder: (configController) {
          return (GetPlatform.isWeb && configController.config == null)
              ? const SizedBox()
              : GetMaterialApp(
                  title: AppConstants.appName,
                  debugShowCheckedModeBanner: false,
                  navigatorKey: Get.key,
                  scrollBehavior: const MaterialScrollBehavior().copyWith(
                    dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
                  ),
                  theme: themeController.darkTheme ? darkTheme : lightTheme,
                  locale: localizeController.locale,
                  translations: Messages(languages: widget.languages),
                  fallbackLocale: Locale(AppConstants.languages[0].languageCode, AppConstants.languages[0].countryCode),
                  initialRoute: RouteHelper.getSplashRoute(notificationData: widget.notificationData),
                  getPages: RouteHelper.routes,
                  defaultTransition: Transition.fade,
                  transitionDuration: const Duration(milliseconds: 500),
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.95)),
                      child: SafeArea(
                        top: false,
                        child: GetBuilder<RideController>(builder: (rideController) {
                          return Stack(
                            children: [
                              child!,
                              if (rideController.notSplashRoute) ...[
                                if (!(Get.find<SplashController>().config!.maintenanceMode != null &&
                                        Get.find<SplashController>().config!.maintenanceMode!.maintenanceStatus == 1 &&
                                        Get.find<SplashController>()
                                                .config!
                                                .maintenanceMode!
                                                .selectedMaintenanceSystem!
                                                .driverApp ==
                                            1) ||
                                    Get.find<SplashController>().haveOngoingRides()) ...[
                                  Positioned(
                                    top: Get.height * 0.3,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () async {
                                        Response res = await rideController.getRideDetails(rideController.rideId ?? '1',
                                            fromHomeScreen: true);
                                        if (res.statusCode == 403 ||
                                            rideController.tripDetail?.currentStatus == 'returning' ||
                                            rideController.tripDetail?.currentStatus == 'returned') {
                                          Get.find<map_ctrl.RiderMapController>()
                                              .setRideCurrentState(map_ctrl.RideState.initial);
                                        }
                                        Get.to(() => const MapScreen());
                                      },
                                      onHorizontalDragEnd: (DragEndDetails details) {
                                        _onHorizontalDrag(details);
                                        Get.to(() => const MapScreen());
                                      },
                                      child: Stack(children: [
                                        SizedBox(
                                            width: Dimensions.iconSizeExtraLarge,
                                            child: Image.asset(Images.homeToMapIcon,
                                                color: Theme.of(context).primaryColor)),
                                        Positioned(
                                            top: 0,
                                            bottom: 0,
                                            left: 5,
                                            right: 5,
                                            child: SizedBox(
                                                width: 15,
                                                child: Image.asset(Images.map,
                                                    color: Get.isDarkMode
                                                        ? Theme.of(context).textTheme.bodyMedium!.color
                                                        : Theme.of(context).colorScheme.shadow)))
                                      ]),
                                    ),
                                  ),
                                ]
                              ]
                            ],
                          );
                        }),
                      ),
                    );
                  });
        });
      });
    });
  }

  void _onHorizontalDrag(DragEndDetails details) {
    if (details.primaryVelocity == 0) return;

    if (details.primaryVelocity!.compareTo(0) == -1) {
      debugPrint('dragged from left');
    } else {
      debugPrint('dragged from right');
    }
  }
}
