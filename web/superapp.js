// Telebirr SuperApp H5 bridge (xm.js + token helpers in one file for reliable deploy).
(function (global) {
  "use strict";

  function debugLog(level, message) {
    try {
      if (!global.__superappDebugBuffer) global.__superappDebugBuffer = [];
      global.__superappDebugBuffer.push({
        level: level,
        message: message,
        ts: Date.now(),
      });
    } catch (_) {}
    try {
      if (global.console && typeof global.console.log === "function") {
        global.console.log("[superapp.js] " + message);
      }
    } catch (_) {}
  }

  // Default navigation fallback for hosts without a custom handler.
  // Redirects to the app's login route. Modify `SUPERAPP_LOGIN_PATH` if needed.
  var SUPERAPP_LOGIN_PATH = '/#/login';
  try {
    if (typeof global.navigateToLogin !== 'function') {
      global.navigateToLogin = function () {
        try {
          debugLog('INFO', 'Default navigateToLogin redirecting to ' + SUPERAPP_LOGIN_PATH);
          global.location.href = SUPERAPP_LOGIN_PATH;
        } catch (e) {
          debugLog('ERROR', 'navigateToLogin failed: ' + String(e));
        }
      };
      debugLog('INFO', 'Default navigateToLogin installed');
    }
  } catch (_) {}

  function mapNativeToEvaluateFunction(nativeName) {
    if (nativeName === "getMiniAppToken") {
      return "js_fun_h5GetAccessToken";
    }
    return nativeName;
  }

  function installXmBridge() {
    if (global.xm && typeof global.xm.native === "function") {
      debugLog("INFO", "window.xm.native already present (host injected)");
      return;
    }

    function xmNative(name, params) {
      params = params || {};
      var evaluateName = mapNativeToEvaluateFunction(name);

      return new Promise(function (resolve, reject) {
        var callbackName =
          "__xmCb_" + Date.now() + "_" + Math.floor(Math.random() * 100000);
        var settled = false;
        var timer = global.setTimeout(function () {
          finish(false, new Error("xm.native timeout: " + name));
        }, 30000);

        function cleanup() {
          global.clearTimeout(timer);
          try {
            delete global[callbackName];
          } catch (_) {
            global[callbackName] = undefined;
          }
        }

        function finish(ok, value) {
          if (settled) return;
          settled = true;
          cleanup();
          if (ok) resolve(value);
          else reject(value);
        }

        global[callbackName] = function () {
          var args = Array.prototype.slice.call(arguments);
          debugLog(
            "INFO",
            "xm.native callback " +
              name +
              " argc=" +
              args.length +
              " types=" +
              args.map(function (a) {
                return typeof a;
              }).join(",")
          );
          for (var i = 0; i < args.length; i++) {
            if (args[i] !== undefined && args[i] !== null) {
              finish(true, args[i]);
              return;
            }
          }
          finish(false, new Error("xm.native callback empty response"));
        };

        var payload = {
          functionName: evaluateName,
          params: {
            appid: params.appId || params.appid || "",
            appId: params.appId || params.appid || "",
            functionCallBackName: callbackName,
            functionCallbackName: callbackName,
          },
        };

        debugLog(
          "INFO",
          "xm.native call name=" +
            name +
            " evaluate=" +
            evaluateName +
            " appId=" +
            payload.params.appId
        );

        if (
          !global.consumerapp ||
          typeof global.consumerapp.evaluate !== "function"
        ) {
          finish(false, new Error("consumerapp.evaluate unavailable"));
          return;
        }

        invokeEvaluate(payload, function (syncResult) {
          if (syncResult !== undefined && syncResult !== null) {
            debugLog("INFO", "xm.native sync response for " + name);
            finish(true, syncResult);
          }
        }, function (err) {
          finish(false, err);
        });
      });
    }

    global.xm = { native: xmNative };
    debugLog("SUCCESS", "window.xm.native installed");
  }

  function invokeEvaluate(payload, onSync, onError) {
    var jsonPayload = JSON.stringify(payload);
    var attempts = [
      function () {
        return global.consumerapp.evaluate(jsonPayload);
      },
      function () {
        return global.consumerapp.evaluate(payload);
      },
    ];

    for (var i = 0; i < attempts.length; i++) {
      try {
        var syncResult = attempts[i]();
        if (onSync) onSync(syncResult);
        return;
      } catch (e) {
        if (i === attempts.length - 1 && onError) onError(e);
      }
    }
  }

  function hasXmNative() {
    return !!(global.xm && typeof global.xm.native === "function");
  }

  function hasConsumerEvaluate() {
    return !!(
      global.consumerapp && typeof global.consumerapp.evaluate === "function"
    );
  }

  function hasMiniAppBridge() {
    return hasXmNative() || hasConsumerEvaluate();
  }

  function waitForBridge(options) {
    options = options || {};
    var timeoutMs = Number(options.timeoutMs || 12000);
    var intervalMs = Number(options.intervalMs || 120);
    var startedAt = Date.now();

    return new Promise(function (resolve) {
      function check() {
        installXmBridge();
        if (hasMiniAppBridge()) {
          debugLog("SUCCESS", "SuperApp bridge detected");
          try {
            if (typeof window.CustomEvent === "function") {
              window.dispatchEvent(
                new CustomEvent("superapp:detectionComplete", {
                  detail: { isSuperApp: true },
                })
              );
            }
          } catch (_) {}
          resolve(true);
          return;
        }

        if (Date.now() - startedAt >= timeoutMs) {
          debugLog(
            "WARN",
            "Bridge unavailable (timeout after " + timeoutMs + "ms)"
          );
          try {
            if (typeof window.CustomEvent === "function") {
              window.dispatchEvent(
                new CustomEvent("superapp:detectionComplete", {
                  detail: { isSuperApp: false },
                })
              );
            }
          } catch (_) {}

          // If host provided a navigation helper, call it to navigate to login.
          try {
            if (typeof window.navigateToLogin === "function") {
              debugLog("INFO", "Calling window.navigateToLogin() due to missing SuperApp");
              try {
                window.navigateToLogin();
              } catch (e) {
                debugLog("ERROR", "navigateToLogin() threw: " + String(e));
              }
            }
          } catch (_) {}

          resolve(false);
          return;
        }

        setTimeout(check, intervalMs);
      }

      check();
    });
  }

  function readToken(response) {
    var data = response;

    if (typeof response === "string") {
      try {
        data = JSON.parse(response);
      } catch (_) {
        if (response.length > 0) return response;
        throw new Error("getMiniAppToken response was not valid JSON");
      }
    }

    if (typeof data === "string" && data.length > 0) {
      return data;
    }

    if (data && typeof data.token === "string" && data.token.length > 0) {
      return data.token;
    }

    if (data && typeof data.accessToken === "string" && data.accessToken.length > 0) {
      return data.accessToken;
    }

    if (data && data.data && typeof data.data.token === "string" && data.data.token.length > 0) {
      return data.data.token;
    }

    if (data && data.data && typeof data.data.accessToken === "string" && data.data.accessToken.length > 0) {
      return data.data.accessToken;
    }

    throw new Error("getMiniAppToken response did not contain token");
  }

  function evaluateForToken(appId, functionName) {
    if (!hasConsumerEvaluate()) {
      return Promise.reject(new Error("consumerapp.evaluate is unavailable"));
    }

    return new Promise(function (resolve, reject) {
      var callbackName =
        "__helloEqubMiniAppTokenCallback_" +
        Date.now() +
        "_" +
        Math.floor(Math.random() * 100000);
      var settled = false;
      var timer = global.setTimeout(function () {
        finish(
          false,
          new Error(
            "consumerapp.evaluate token callback timeout (" + functionName + ")"
          )
        );
      }, 30000);

      function cleanup() {
        global.clearTimeout(timer);
        try {
          delete global[callbackName];
        } catch (_) {
          global[callbackName] = undefined;
        }
      }

      function finish(ok, value) {
        if (settled) return;
        settled = true;
        cleanup();
        if (ok) resolve(value);
        else reject(value);
      }

      global[callbackName] = function () {
        var args = Array.prototype.slice.call(arguments);
        debugLog("INFO", "evaluate callback " + functionName + " argc=" + args.length);
        for (var i = 0; i < args.length; i++) {
          try {
            finish(true, readToken(args[i]));
            return;
          } catch (_) {}
        }
        finish(
          false,
          new Error("consumerapp.evaluate callback did not contain token")
        );
      };

      var payload = {
        functionName: functionName,
        params: {
          appid: appId,
          appId: appId,
          functionCallBackName: callbackName,
          functionCallbackName: callbackName,
        },
      };

      debugLog(
        "INFO",
        "consumerapp.evaluate functionName=" + functionName + " appId=" + appId
      );

      invokeEvaluate(
        payload,
        function (syncResult) {
          if (syncResult !== undefined && syncResult !== null) {
            debugLog("INFO", "consumerapp.evaluate sync response for " + functionName);
            try {
              finish(true, readToken(syncResult));
            } catch (e) {
              finish(false, e);
            }
          }
        },
        function (err) {
          finish(false, err);
        }
      );
    });
  }

  function getTokenFromConsumerApp(appId) {
    var attempts = [
      "js_fun_h5GetAccessToken",
      "getMiniAppToken",
      "js_fun_getAccessToken",
    ];

    function run(index) {
      if (index >= attempts.length) {
        return Promise.reject(
          new Error("consumerapp.evaluate token attempts exhausted")
        );
      }
      return evaluateForToken(appId, attempts[index]).catch(function (err) {
        debugLog("WARN", attempts[index] + " failed: " + err);
        return run(index + 1);
      });
    }

    return run(0);
  }

  function getTokenFromXmNative(appId) {
    installXmBridge();
    if (!hasXmNative()) {
      return Promise.reject(new Error("xm.native is unavailable"));
    }

    debugLog("INFO", "calling xm.native(getMiniAppToken) appId=" + appId);
    return global.xm
      .native("getMiniAppToken", { appId: appId })
      .then(readToken);
  }

  function getMiniAppToken(appId) {
    installXmBridge();

    if (hasXmNative()) {
      return getTokenFromXmNative(appId).catch(function (xmError) {
        debugLog("WARN", "xm.native failed: " + xmError);
        if (hasConsumerEvaluate()) {
          return getTokenFromConsumerApp(appId);
        }
        throw xmError;
      });
    }

    if (hasConsumerEvaluate()) {
      return getTokenFromConsumerApp(appId);
    }

    return Promise.reject(new Error("SuperApp bridge is unavailable"));
  }

  installXmBridge();

  function exchangeAuthToken(gatewayUrl, authToken) {
    debugLog("INFO", "fetch POST auth/token url=" + gatewayUrl);
    return fetch(gatewayUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ authToken: authToken }),
    }).then(function (res) {
      return res.text().then(function (text) {
        var json = {};
        try {
          json = text ? JSON.parse(text) : {};
        } catch (_) {
          throw new Error("gateway auth/token invalid JSON: " + text.slice(0, 200));
        }
        if (!res.ok) {
          throw new Error(
            json.errorMsg ||
              json.message ||
              json.msg ||
              "HTTP " + res.status
          );
        }
        debugLog("SUCCESS", "gateway auth/token ok");
        return json;
      });
    });
  }

  global.SuperAppBridge = {
    isAvailable: hasMiniAppBridge,
    hasXmNative: hasXmNative,
    hasConsumerEvaluate: hasConsumerEvaluate,
    waitForBridge: waitForBridge,
    getMiniAppToken: getMiniAppToken,
    installXmBridge: installXmBridge,
    exchangeAuthToken: exchangeAuthToken,
  };

  global.isSuperAppWebView = hasMiniAppBridge;
  global.getMiniAppToken = getMiniAppToken;
})(window);
