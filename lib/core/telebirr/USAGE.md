# Telebirr Mini App Detection (Flutter Web Only)

## Overview

This module provides **web-only** detection and bridge access for running inside the **Telebirr Mini App** (Telebirr's WebView container).

**Critical Rule**: This entire folder (`lib/core/telebirr/`) is designed so that:
- On **Flutter Web** → real Telebirr bridge detection and calls work.
- On **Android / iOS / Desktop** → all methods safely return "not in Telebirr" behavior.
- **Zero changes** are required (or allowed) in any Android native code.

## Files

| File | Purpose | Platform |
|------|---------|----------|
| `telebirr.dart` | Barrel export (recommended import) | All |
| `telebirr_mini_app_detector.dart` | Abstract interface | All |
| `telebirr_mini_app_detector_web.dart` | Real JS interop implementation | Web only |
| `telebirr_mini_app_detector_stub.dart` | Safe no-op stub | Android/iOS/Desktop |
| `telebirr_web_payment_helper.dart` | High-level payment helper | All (logic is web-only) |
| `USAGE.md` | This file | Docs |

## Basic Usage

```dart
import 'package:flutter/foundation.dart';
import 'package:helloequb/core/telebirr/telebirr.dart';

// 1. Detection
final detector = createTelebirrMiniAppDetector();

if (kIsWeb) {
  final insideTelebirr = detector.isTelebirrMiniApp();
  final snapshot = detector.getBridgeSnapshot();
  
  print('Inside Telebirr Mini App: $insideTelebirr');
  print('Bridge snapshot: $snapshot');
}

// 2. Get auth token (web only)
if (kIsWeb && detector.isTelebirrMiniApp()) {
  final token = await detector.getMiniAppToken(appId: 'your_merchant_app_id');
}

// 3. Start payment via Telebirr bridge (web only)
if (kIsWeb) {
  final helper = TelebirrWebPaymentHelper();
  
  if (helper.isInsideTelebirrMiniApp) {
    final result = await helper.startPayment(rawRequestFromBackend);
    if (result.success) {
      // Payment initiated inside Telebirr
    } else {
      // Show error or fallback UI
    }
  } else {
    // User opened the web app in a normal browser
    // Show "Please open from inside Telebirr" message
  }
}
```

## Integration in Auth Flow (Web)

The existing `SuperAppAuthBloc` already handles SuperApp detection. You can optionally enhance it with the new Telebirr detector as a secondary check:

```dart
// In your auth initialization code (web only)
import 'package:helloequb/core/telebirr/telebirr.dart';

Future<void> initializeAuth() async {
  if (!kIsWeb) return; // Android path untouched

  final detector = createTelebirrMiniAppDetector();
  
  if (!detector.isTelebirrMiniApp()) {
    // Not inside Telebirr → redirect to "open in Telebirr" page
    context.go('/not-superapp');
    return;
  }

  // Optional: get token directly if needed before backend exchange
  final miniToken = await detector.getMiniAppToken(appId: merchantAppId);
  if (miniToken != null) {
    // Use token for backend exchange...
  }
}
```

## Integration in Payment Flow (Web)

**Never modify** `lib/core/telebirr_service.dart` (Android MethodChannel).

Instead, branch at the call site using `kIsWeb`:

```dart
import 'package:flutter/foundation.dart';
import 'package:helloequb/core/telebirr/telebirr.dart';
import 'package:helloequb/core/telebirr_service.dart'; // Android only

Future<void> handleTelebirrPayment({
  required String rawRequest,
  required String appId,
  required String shortCode,
  // ... other params
}) async {
  if (kIsWeb) {
    // ========== WEB + TELEBIRR MINI APP PATH ==========
    final helper = TelebirrWebPaymentHelper();

    if (!helper.isInsideTelebirrMiniApp) {
      // Show friendly message
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Telebirr Required'),
          content: const Text(
            'Please open this app from inside the Telebirr Mini App to make payments.',
          ),
        ),
      );
      return;
    }

    final result = await helper.startPayment(rawRequest);

    if (result.success) {
      // Payment sheet opened inside Telebirr
      // Listen for result via Telebirr callback if needed
    } else {
      showError(result.message ?? 'Payment failed');
    }
  } else {
    // ========== ANDROID (EXISTING) PATH - DO NOT TOUCH ==========
    final androidService = TelebirrService();
    await androidService.initiatePayment(
      appId: appId,
      shortCode: shortCode,
      appKey: appSecret,
      totalAmount: amount,
      receiveCode: receiveCode,
    );
  }
}
```

## Recommended Pattern: Payment Screen Update

In `payment_screen.dart`, the `_startTelebirrPayment()` method currently only calls the Android service.

You can wrap it like this (example only — do not break existing flow):

```dart
Future<void> _startTelebirrPayment() async {
  final rawRequest = ...; // the raw_request from your backend

  if (kIsWeb) {
    final helper = TelebirrWebPaymentHelper();
    final result = await helper.startPayment(rawRequest);
    
    if (!result.success) {
      _showDialog('Payment Error', result.message ?? 'Failed');
    }
    return;
  }

  // Existing Android code path (unchanged)
  await _telebirrService.initiatePayment(...);
}
```

## Diagnostics / Debugging

```dart
final detector = createTelebirrMiniAppDetector();
final info = detector.getBridgeSnapshot();

print(info['has.consumerapp']);   // true if window.consumerapp exists
print(info['has.xm']);            // true if window.xm exists
print(info['has.xm.native']);     // true if xm.native is a function
print(info['userAgent']);
```

You can also use the existing **SuperApp Debug Overlay** (enabled by default on web) which shows bridge detection logs.

## Testing Checklist

### On Web (inside Telebirr Mini App)
- [ ] `detector.isTelebirrMiniApp()` returns `true`
- [ ] `getMiniAppToken()` returns a valid token string
- [ ] `startPayment(rawRequest)` opens the Telebirr payment sheet
- [ ] Payment result callbacks are received (if your backend posts them back)

### On Web (normal browser)
- [ ] `detector.isTelebirrMiniApp()` returns `false`
- [ ] `startPayment(...)` returns `{ success: false, error: 'NOT_IN_TELEBIRR' }`
- [ ] User sees a clear "open inside Telebirr" message

### On Android App
- [ ] **No changes** to any Android code or `TelebirrService`
- [ ] `createTelebirrMiniAppDetector().isTelebirrMiniApp()` returns `false`
- [ ] Existing payment flow via MethodChannel continues to work exactly as before

## Important Notes

1. **Do not import** `telebirr_mini_app_detector_web.dart` or `_stub.dart` directly anywhere. Always go through the barrel or the factory function.
2. The existing `superapp_bridge.dart` system (for auth) is separate but follows the same conditional import pattern. You can use both.
3. `window.consumerapp.evaluate(...)` and `window.xm.native(...)` are the two most common bridge entry points. This detector tries both.
4. If Telebirr changes their bridge in the future, only update the `_web.dart` file.

## Related Existing Systems

- `lib/core/superapp/` — Existing SuperApp auth bridge (already working)
- `lib/core/telebirr_service.dart` — Android-only MethodChannel payments (do not touch)
- `web/superapp.js` — JS helper injected for auth token retrieval
