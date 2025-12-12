import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dir_delivery_driver/helper/isolate_manager.dart';
import 'package:system_alert_window/system_alert_window.dart';

/// Overlay widget that displays incoming trip requests
/// Reuses the same design as CustomerRideRequestCardWidget
class IncomingTripOverlayWidget extends StatefulWidget {
  const IncomingTripOverlayWidget({super.key});

  @override
  State<IncomingTripOverlayWidget> createState() => _IncomingTripOverlayWidgetState();
}

class _IncomingTripOverlayWidgetState extends State<IncomingTripOverlayWidget> {
  Map<String, dynamic>? _tripData;
  bool _hasReceivedData = false;
  bool _isClosing = false; // Prevent multiple close calls

  @override
  void initState() {
    super.initState();
    _listenForData();
    // Also try to get initial data after a delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!_hasReceivedData && mounted) {
        if (kDebugMode) {
          print('Overlay: No data received after delay, showing default');
        }
        // Show default data if nothing received
        setState(() {
          _tripData = {
            'title': 'New trip request',
            'body': 'Tap Accept to view details',
            'type': 'ride_request',
          };
        });
      }
    });
  }

  /// Listen for data shared from main app
  void _listenForData() {
    if (kDebugMode) {
      print('Overlay: Setting up listener...');
    }

    SystemAlertWindow.overlayListener.listen((event) {
      if (kDebugMode) {
        print('Overlay received data: $event (type: ${event.runtimeType})');
      }
      try {
        // The event might be a string or already a Map
        Map<String, dynamic> data;
        if (event is String) {
          data = jsonDecode(event);
        } else if (event is Map) {
          data = Map<String, dynamic>.from(event);
        } else {
          // Try to convert to string first
          final String eventString = event.toString();
          data = jsonDecode(eventString);
        }

        // Ignore messages sent from overlay itself (reject/open_trip/close_overlay/open_trip_from_overlay actions)
        if (data['action'] == 'reject_trip' ||
            data['action'] == 'accept_trip' ||
            data['action'] == 'open_trip' ||
            data['action'] == 'open_trip_from_overlay' ||
            data['action'] == 'close_overlay') {
          if (kDebugMode) {
            print('Overlay: Ignoring self-sent message: ${data['action']}');
          }
          return;
        }

        if (kDebugMode) {
          print('Overlay: Parsed data successfully: $data');
          print('Overlay: Available keys: ${data.keys.toList()}');
          print('Overlay: user_name: ${data['user_name']}');
          print('Overlay: estimated_fare: ${data['estimated_fare']}');
          print('Overlay: pickup_address: ${data['pickup_address']}');
          print('Overlay: destination_address: ${data['destination_address']}');
        }

        setState(() {
          _tripData = data;
          _hasReceivedData = true;
        });
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('Failed to parse overlay data: $e');
          print('Stack trace: $stackTrace');
          print('Event type: ${event.runtimeType}');
          print('Event value: $event');
        }
      }
    });

    if (kDebugMode) {
      print('Overlay: Listener set up');
    }
  }

  /// View trip - opens app and shows trip details
  Future<void> _viewTrip() async {
    if (_isClosing) return;
    _isClosing = true;

    try {
      if (kDebugMode) {
        print('Overlay: View called - opening app and showing trip');
      }

      final rideRequestId = _tripData?['ride_request_id'];

      if (rideRequestId != null) {
        // Send message to main app via IsolateNameServer (proper way to send FROM overlay TO main app)
        try {
          SendPort? sendPort = IsolateManager.lookupPortByName();
          if (sendPort != null) {
            final message = jsonEncode({
              'action': 'open_trip_from_overlay',
              'ride_request_id': rideRequestId,
            });
            sendPort.send(message);
            if (kDebugMode) {
              print('Overlay: Sent message to main app via IsolateNameServer: $message');
            }
          } else {
            if (kDebugMode) {
              print('Overlay: SendPort not found, trying fallback method');
            }
            // Fallback: try overlayListener method
            final message = jsonEncode({
              'action': 'open_trip_from_overlay',
              'ride_request_id': rideRequestId,
            });
            await SystemAlertWindow.sendMessageToOverlay(message);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Overlay: Error sending via IsolateNameServer: $e');
            print('Overlay: Trying fallback - sending message via overlay listener');
          }
          // Fallback: try to send message via overlay listener
          final message = jsonEncode({
            'action': 'open_trip_from_overlay',
            'ride_request_id': rideRequestId,
          });
          await SystemAlertWindow.sendMessageToOverlay(message);
        }

        // Wait a bit to ensure message is received before closing
        await Future.delayed(const Duration(milliseconds: 300));

        if (kDebugMode) {
          print('Overlay: View message sent - ride_request_id: $rideRequestId');
        }

        // Close overlay after sending message
        await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Overlay: Error viewing trip: $e');
      }
      _isClosing = false;
    }
  }

  /// Dismiss/Close the overlay
  Future<void> _dismiss() async {
    if (_isClosing) return;
    _isClosing = true;

    try {
      if (kDebugMode) {
        print('Overlay: Dismiss called - closing overlay');
      }

      // Close overlay directly
      await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
    } catch (e) {
      if (kDebugMode) {
        print('Overlay: Error closing overlay: $e');
      }
      _isClosing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // App primary color - matching CustomerRideRequestCardWidget
    const Color primaryColor = Color(0xFFA61E49);
    const Color surfaceContainer = Color(0xFF0094FF);
    const double paddingSizeSmall = 10.0;
    const double paddingSizeDefault = 15.0;
    const double paddingSizeLarge = 20.0;
    const double paddingSizeExtraSmall = 5.0;
    const double iconSizeMedium = 20.0;

    // If no data yet, show loading
    if (_tripData == null) {
      return SizedBox(
        width: 360,
        height: 280,
        child: Container(
          padding: const EdgeInsets.all(paddingSizeSmall),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(paddingSizeDefault),
            border: Border.all(color: primaryColor, width: 0.35),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 1,
                spreadRadius: 1,
                offset: const Offset(0, 0),
              )
            ],
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
        ),
      );
    }

    final String type =
        _tripData!['type'] ?? (_tripData!['action'] == 'new_parcel_request' ? 'parcel_request' : 'ride_request');
    // Try different possible field names for user name
    final String? userName = _tripData!['user_name'] ??
        _tripData!['customer_name'] ??
        (_tripData!['customer'] != null && _tripData!['customer'] is Map ? _tripData!['customer']['name'] : null);
    // Try different possible field names for fare
    final String? estimatedFare = _tripData!['estimated_fare']?.toString() ?? _tripData!['fare']?.toString();
    final String? estimatedTime = _tripData!['estimated_time']?.toString() ?? _tripData!['time']?.toString();
    final String? estimatedDistance =
        _tripData!['estimated_distance']?.toString() ?? _tripData!['distance']?.toString();
    final String? pickupAddress = _tripData!['pickup_address'] ?? _tripData!['pickup'] ?? _tripData!['from_address'];
    final String? destinationAddress =
        _tripData!['destination_address'] ?? _tripData!['destination'] ?? _tripData!['to_address'];
    final String? customerRating = _tripData!['customer_avg_rating']?.toString() ??
        (_tripData!['customer'] != null && _tripData!['customer'] is Map
            ? _tripData!['customer']['avg_rating']?.toString()
            : null);
    final String? customerProfileImage = _tripData!['customer_profile_image'] ??
        (_tripData!['customer'] != null && _tripData!['customer'] is Map
            ? _tripData!['customer']['profile_image']
            : null);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _viewTrip, // Make entire overlay tappable to view trip
        child: SizedBox(
          width: 360,
          height: 480, // Match the height set in overlay_helper - increased to fit all content
          child: Container(
            padding: const EdgeInsets.all(paddingSizeSmall),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(paddingSizeDefault),
              border: Border.all(color: primaryColor, width: 0.35),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 1,
                  spreadRadius: 1,
                  offset: const Offset(0, 0),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Trip type header - matching CustomerRideRequestCardWidget
                          Padding(
                            padding: const EdgeInsets.only(top: paddingSizeDefault, bottom: paddingSizeDefault),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Trip Type',
                                  style: TextStyle(
                                    fontFamily: 'SFProText',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF202020),
                                  ),
                                ),
                                const SizedBox(width: paddingSizeExtraSmall),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: paddingSizeSmall,
                                    vertical: paddingSizeExtraSmall,
                                  ),
                                  decoration: BoxDecoration(
                                    color: surfaceContainer,
                                    borderRadius: BorderRadius.circular(paddingSizeExtraSmall),
                                  ),
                                  child: Text(
                                    type == 'parcel_request' ? 'Parcel' : 'Ride',
                                    style: const TextStyle(
                                      fontFamily: 'SFProText',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Close button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _dismiss,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Estimated time and distance - matching CustomerRideRequestCardWidget
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA800).withOpacity(0.2), // primaryContainer
                    borderRadius: BorderRadius.circular(paddingSizeSmall),
                  ),
                  padding: const EdgeInsets.all(paddingSizeSmall),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Color(0xFF666666)),
                          const SizedBox(width: paddingSizeExtraSmall),
                          Text(
                            estimatedTime != null ? '$estimatedTime min away' : 'New request',
                            style: const TextStyle(
                              fontFamily: 'SFProText',
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                      if (estimatedDistance != null)
                        Text(
                          'Distance: ${double.tryParse(estimatedDistance)?.toStringAsFixed(2) ?? estimatedDistance} Km',
                          style: const TextStyle(
                            fontFamily: 'SFProText',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: paddingSizeSmall),
                // Route information
                if (pickupAddress != null || destinationAddress != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: paddingSizeExtraSmall),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Route icons
                        Column(
                          children: [
                            SizedBox(
                              width: iconSizeMedium,
                              child: const Icon(
                                Icons.location_on,
                                size: iconSizeMedium,
                                color: Color(0xFF666666),
                              ),
                            ),
                            SizedBox(
                              height: 50,
                              width: 10,
                              child: CustomPaint(
                                painter: DashedLinePainter(),
                              ),
                            ),
                            SizedBox(
                              width: iconSizeMedium,
                              child: const Icon(
                                Icons.flag,
                                size: iconSizeMedium,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: paddingSizeSmall),
                        // Addresses
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (pickupAddress != null)
                                SizedBox(
                                  height: 40,
                                  child: Text(
                                    pickupAddress,
                                    style: const TextStyle(
                                      fontFamily: 'SFProText',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                      color: Color(0xFF666666),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              const SizedBox(height: paddingSizeLarge),
                              if (destinationAddress != null)
                                Text(
                                  destinationAddress,
                                  style: const TextStyle(
                                    fontFamily: 'SFProText',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Customer info and fare
                if (userName != null || estimatedFare != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: paddingSizeDefault,
                      horizontal: paddingSizeSmall,
                    ),
                    child: Row(
                      children: [
                        // Customer avatar
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(0.1),
                            image: customerProfileImage != null && customerProfileImage.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(customerProfileImage),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: customerProfileImage == null || customerProfileImage.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: primaryColor,
                                  size: 30,
                                )
                              : null,
                        ),
                        const SizedBox(width: paddingSizeExtraSmall),
                        // Customer name and rating
                        if (userName != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontFamily: 'SFProText',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    color: Color(0xFF202020),
                                  ),
                                ),
                                if (customerRating != null && customerRating.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rate_rounded,
                                        color: Color(0xFFFFA800),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        double.tryParse(customerRating)?.toStringAsFixed(1) ?? customerRating,
                                        style: const TextStyle(
                                          fontFamily: 'SFProText',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        // Estimated fare
                        if (estimatedFare != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Estimated Fare',
                                style: TextStyle(
                                  fontFamily: 'SFProText',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: Color(0xFFA61E49),
                                ),
                              ),
                              Text(
                                estimatedFare,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Color(0xFFA61E49),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                // View button - single button to open app and show trip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: paddingSizeDefault),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _viewTrip,
                      style: TextButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(paddingSizeSmall),
                        ),
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(
                          fontFamily: 'SFProText',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: paddingSizeExtraSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for dashed line between pickup and destination icons
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF666666)
      ..strokeWidth = 2;

    const double dashHeight = 3;
    const double dashSpace = 3;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
