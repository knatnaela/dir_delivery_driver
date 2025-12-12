import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:system_alert_window/system_alert_window.dart';

/// Helper for an incoming-trip overlay using system_alert_window package.
/// Follows the official package documentation: https://pub.dev/packages/system_alert_window
class OverlayHelper {
  /// Show the incoming trip overlay using system_alert_window
  /// The package handles background execution through its foreground service
  static Future<void> showIncomingTripOverlay(Map<String, dynamic> data) async {
    if (!Platform.isAndroid) {
      if (kDebugMode) {
        debugPrint('OverlayHelper: Not Android, skipping overlay');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('OverlayHelper: showIncomingTripOverlay called with action: ${data['action']}');
    }

    try {
      if (kDebugMode) {
        debugPrint('OverlayHelper: Starting overlay display process');
      }

      // Check permission first
      bool hasPermission = false;
      try {
        hasPermission = await hasOverlayPermission();
        if (kDebugMode) {
          debugPrint('OverlayHelper: Permission check result: $hasPermission');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('OverlayHelper: Error checking permission: $e');
        }
        hasPermission = false;
      }

      if (!hasPermission) {
        if (kDebugMode) {
          debugPrint('OverlayHelper: Overlay permission not granted - overlay will not show');
          debugPrint('OverlayHelper: User needs to grant SYSTEM_ALERT_WINDOW permission');
        }
        return;
      }

      final String payload = jsonEncode(data);
      final String title = data['title'] ?? 'New trip request';
      final String body = data['body'] ?? '';

      if (kDebugMode) {
        debugPrint('OverlayHelper: Attempting to show overlay - title: $title, body: $body');
        debugPrint(
            'OverlayHelper: Data to send - user_name: ${data['user_name']}, estimated_fare: ${data['estimated_fare']}, pickup_address: ${data['pickup_address']}');
        debugPrint('OverlayHelper: Full payload length: ${payload.length}');
      }

      // Close any existing overlay first
      try {
        if (kDebugMode) {
          debugPrint('OverlayHelper: Closing any existing overlay first');
        }
        await SystemAlertWindow.closeSystemWindow();
        // Wait a bit for overlay to close
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('OverlayHelper: Error closing existing overlay (non-critical): $e');
        }
        // Continue anyway - might not have an existing overlay
      }

      // Show overlay with custom size and position
      // Following README: https://pub.dev/packages/system_alert_window
      if (kDebugMode) {
        debugPrint('OverlayHelper: Calling SystemAlertWindow.showSystemWindow()');
        debugPrint('OverlayHelper: Parameters - height: 480, width: 360, gravity: CENTER, prefMode: OVERLAY');
      }

      try {
        await SystemAlertWindow.showSystemWindow(
          height: 480, // Increased height to fit all content without scrolling
          width: 360, // Width to match new design
          gravity: SystemWindowGravity.CENTER,
          notificationTitle: title,
          notificationBody: body,
          prefMode: SystemWindowPrefMode.OVERLAY, // Use overlay mode (bubbles on Android 11+)
        );

        if (kDebugMode) {
          debugPrint('OverlayHelper: showSystemWindow() completed successfully');
        }

        // Wait longer for overlay to fully initialize and listener to be ready
        await Future.delayed(const Duration(milliseconds: 1000));

        // Send data to overlay widget using sendMessageToOverlay()
        // The method accepts a String (as shown in example: sendMessageToOverlay("Hello from the other side"))
        // We're sending a JSON-encoded string which is correct
        if (kDebugMode) {
          debugPrint('OverlayHelper: Sending data to overlay (String payload, length: ${payload.length})');
          debugPrint(
              'OverlayHelper: Payload preview: ${payload.length > 200 ? payload.substring(0, 200) + "..." : payload}');
        }
        await SystemAlertWindow.sendMessageToOverlay(payload);

        // Send again after a short delay to ensure it's received
        await Future.delayed(const Duration(milliseconds: 300));
        await SystemAlertWindow.sendMessageToOverlay(payload);

        if (kDebugMode) {
          debugPrint('OverlayHelper: Data sent to overlay successfully (sent twice for reliability)');
        }

        if (kDebugMode) {
          debugPrint('OverlayHelper: Overlay shown successfully and data sent');
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('OverlayHelper: ERROR in showSystemWindow(): $e');
          debugPrint('OverlayHelper: Stack trace: $stackTrace');
        }
        rethrow; // Re-throw to be caught by outer catch
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('OverlayHelper: Failed to show overlay: $e');
        debugPrint('OverlayHelper: Stack trace: $stackTrace');
      }
    }
  }

  /// Hide the overlay
  /// Following README: https://pub.dev/packages/system_alert_window
  static Future<void> hideOverlay() async {
    if (!Platform.isAndroid) return;
    try {
      await SystemAlertWindow.closeSystemWindow();
      if (kDebugMode) {
        debugPrint('OverlayHelper: Overlay closed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OverlayHelper: Failed to close overlay: $e');
      }
    }
  }

  /// Check if overlay permission is granted
  /// Following README: https://pub.dev/packages/system_alert_window
  static Future<bool> hasOverlayPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      // system_alert_window uses checkPermissions which returns a Future<bool?>
      final bool? result = await SystemAlertWindow.checkPermissions();
      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OverlayHelper: Failed to check overlay permission: $e');
      }
      return false;
    }
  }

  /// Request overlay permission by opening the system settings screen
  /// Following README: https://pub.dev/packages/system_alert_window
  static Future<void> requestOverlayPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await SystemAlertWindow.requestPermissions;
      if (kDebugMode) {
        debugPrint('OverlayHelper: Permission request sent');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OverlayHelper: Failed to request overlay permission: $e');
      }
    }
  }
}
