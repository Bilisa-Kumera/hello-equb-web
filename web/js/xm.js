// Telebirr H5 bridge shim (matches merchant demo: js/xm.js).
// Provides window.xm.native(...) used by AutoLogin documentation.
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
        global.console.log("[xm.js] " + message);
      }
    } catch (_) {}
  }

  function native(name, params) {
    params = params || {};
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

      global[callbackName] = function (res, message, data) {
        debugLog("INFO", "xm.native callback " + name + " res=" + typeof res);
        if (res !== undefined && res !== null) {
          finish(true, res);
          return;
        }
        if (data !== undefined && data !== null) {
          finish(true, data);
          return;
        }
        finish(false, new Error(message || "xm.native callback empty response"));
      };

      var payload = {
        functionName: name,
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
          " appId=" +
          payload.params.appId +
          " cb=" +
          callbackName
      );

      if (
        !global.consumerapp ||
        typeof global.consumerapp.evaluate !== "function"
      ) {
        finish(false, new Error("consumerapp.evaluate unavailable"));
        return;
      }

      try {
        var syncResult = global.consumerapp.evaluate(payload);
        if (syncResult !== undefined && syncResult !== null) {
          debugLog("INFO", "xm.native sync response for " + name);
          finish(true, syncResult);
        }
      } catch (objectError) {
        try {
          global.consumerapp.evaluate(JSON.stringify(payload));
        } catch (stringError) {
          finish(false, stringError || objectError);
        }
      }
    });
  }

  if (!global.xm || typeof global.xm.native !== "function") {
    global.xm = { native: native };
    debugLog("SUCCESS", "window.xm.native installed");
  } else {
    debugLog("INFO", "window.xm.native already present (host injected)");
  }
})(window);
