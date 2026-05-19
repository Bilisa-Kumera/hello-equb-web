// SuperApp (Telebirr-style) H5 bridge wrapper.
// Safe to load in normal browsers (no-op when bridge is missing).
//
// Telebirr injects the bridge asynchronously in some WebViews:
//   window.xm.native(method, params)
//
// This file adds:
//   - Robust polling (wait for injection after Flutter starts)
//   - A JS log buffer + CustomEvent('superapp:log') for Flutter UI overlays
//
// Backwards-compatible globals kept for existing Dart code:
//   - window.isSuperAppWebView(): boolean
//   - window.getMiniAppToken(appId): Promise<string>
(function () {
  "use strict";

  var LOG_BUFFER_KEY = "__superappDebugBuffer";
  var MAX_LOGS = 500;

  function safeString(v) {
    try {
      if (v instanceof Error) return v.message || String(v);
      if (typeof v === "string") return v;
      return JSON.stringify(v);
    } catch (_) {
      return String(v);
    }
  }

  function nowClock() {
    try {
      var d = new Date();
      var hh = String(d.getHours()).padStart(2, "0");
      var mm = String(d.getMinutes()).padStart(2, "0");
      var ss = String(d.getSeconds()).padStart(2, "0");
      return hh + ":" + mm + ":" + ss;
    } catch (_) {
      return "";
    }
  }

  function pushLog(level, message, data) {
    try {
      if (!window[LOG_BUFFER_KEY]) window[LOG_BUFFER_KEY] = [];
      var entry = {
        t: Date.now(),
        ts: nowClock(),
        level: level,
        message: message,
        data: data || null,
      };
      window[LOG_BUFFER_KEY].push(entry);
      if (window[LOG_BUFFER_KEY].length > MAX_LOGS) {
        window[LOG_BUFFER_KEY].splice(
          0,
          window[LOG_BUFFER_KEY].length - MAX_LOGS
        );
      }

      // Flutter can listen to this event and render logs on-screen (no console needed).
      if (typeof window.CustomEvent === "function") {
        window.dispatchEvent(
          new CustomEvent("superapp:log", { detail: entry })
        );
      }
    } catch (_) {
      // Never break app startup due to debug logging.
    }
  }

  function isBridgeAvailableStrict() {
    return (
      typeof window !== "undefined" &&
      window.xm &&
      typeof window.xm.native === "function"
    );
  }

  function detectSnapshot() {
    var out = { hasXm: false, hasNative: false, nativeType: "null" };
    try {
      out.hasXm = !!window.xm;
      if (window.xm) {
        out.hasNative = window.xm.native != null;
        out.nativeType =
          window.xm.native == null ? "null" : typeof window.xm.native;
      }
    } catch (_) {}
    out.ready = isBridgeAvailableStrict();
    return out;
  }

  function isPromiseLike(value) {
    return value && typeof value.then === "function";
  }

  // Best-effort normalization of bridge responses.
  function extractToken(value) {
    if (!value) return null;
    if (typeof value === "string") {
      // SuperApp bridges often return a JSON string, e.g. '{"token":"..."}'
      var s = value.trim();
      if (s.startsWith("{") || s.startsWith("[")) {
        try {
          var parsed = JSON.parse(s);
          return extractToken(parsed);
        } catch (_) {
          // If it's not JSON, treat it as a token string.
        }
      }
      return s;
    }
    if (typeof value === "object") {
      if (typeof value.authToken === "string") return value.authToken;
      if (typeof value.token === "string") return value.token;
      if (value.data && typeof value.data.authToken === "string")
        return value.data.authToken;
      if (value.data && typeof value.data.token === "string")
        return value.data.token;
    }
    return null;
  }

  function waitForBridge(opts) {
    opts = opts || {};
    var timeoutMs = Number(opts.timeoutMs || 12000);
    var intervalMs = Number(opts.intervalMs || 120);
    var maxIntervalMs = Number(opts.maxIntervalMs || 600);

    var start = Date.now();
    var attempt = 0;

    pushLog("INFO", "Checking Telebirr bridge...");

    return new Promise(function (resolve) {
      function tick() {
        attempt += 1;
        var snap = detectSnapshot();

        if (snap.hasXm) pushLog("INFO", "window.xm detected");
        if (snap.hasNative)
          pushLog("INFO", "window.xm.native detected (type=" + snap.nativeType + ")");

        if (snap.ready) {
          pushLog("SUCCESS", "Telebirr bridge ready");
          resolve(true);
          return;
        }

        if (Date.now() - start >= timeoutMs) {
          pushLog("WARN", "Bridge unavailable (timeout after " + timeoutMs + "ms)");
          resolve(false);
          return;
        }

        pushLog("WARN", "Bridge unavailable");
        pushLog("INFO", "Retrying detection... (attempt " + attempt + ")");
        intervalMs = Math.min(maxIntervalMs, Math.floor(intervalMs * 1.15));
        setTimeout(tick, intervalMs);
      }

      tick();
    });
  }

  function getMiniAppToken(appId, opts) {
    opts = opts || {};
    var timeoutMs = Number(opts.timeoutMs || 12000);

    return new Promise(function (resolve, reject) {
      waitForBridge({ timeoutMs: timeoutMs }).then(function (ok) {
        if (!ok) {
          reject(new Error("SuperApp bridge unavailable"));
          return;
        }

        pushLog("INFO", "MiniApp token request started");

        try {
          // Try calling bridge in the most common forms.
          var result;
          try {
            result = window.xm.native("getMiniAppToken", { appId: appId });
          } catch (e) {
            // Some bridges require callbacks instead of returning a value.
            result = null;
          }

          if (isPromiseLike(result)) {
            result
              .then(function (v) {
                var token = extractToken(v);
                if (token) {
                  pushLog("SUCCESS", "MiniApp token received (len=" + token.length + ")");
                  resolve(token);
                  return;
                }
                reject(new Error("Invalid token response"));
              })
              .catch(function (e) {
                pushLog("ERROR", "MiniApp token request failed: " + safeString(e));
                reject(e);
              });
            return;
          }

          var token = extractToken(result);
          if (token) {
            pushLog("SUCCESS", "MiniApp token received (len=" + token.length + ")");
            resolve(token);
            return;
          }

          // Callback-based fallback (best-effort).
          window.xm.native("getMiniAppToken", {
            appId: appId,
            success: function (v) {
              var t = extractToken(v);
              if (t) {
                pushLog("SUCCESS", "MiniApp token received (len=" + t.length + ")");
                resolve(t);
                return;
              }
              reject(new Error("Invalid token response"));
            },
            fail: function (err) {
              var e = err instanceof Error ? err : new Error(String(err));
              pushLog("ERROR", "MiniApp token request failed: " + safeString(e));
              reject(e);
            },
          });
        } catch (e) {
          pushLog("ERROR", "MiniApp token request crashed: " + safeString(e));
          reject(e);
        }
      });
    });
  }

  // Public API for Dart interop and diagnostics.
  window.SuperAppBridge = {
    detect: detectSnapshot,
    isAvailable: isBridgeAvailableStrict,
    waitForBridge: waitForBridge,
    getMiniAppToken: getMiniAppToken,
    _pushLog: pushLog,
  };

  // Backwards-compatible globals used by current Dart code.
  window.isSuperAppWebView = function () {
    return isBridgeAvailableStrict();
  };

  window.getMiniAppToken = function (appId) {
    return getMiniAppToken(appId, {});
  };

  pushLog("INFO", "superapp.js loaded");
})();
