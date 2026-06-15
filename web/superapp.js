// Simple SuperApp H5 bridge wrapper.
// Public API used by Flutter:
//   window.isSuperAppWebView(): boolean
//   window.SuperAppBridge.waitForBridge({ timeoutMs, intervalMs }): Promise<boolean>
//   window.getMiniAppToken(appId): Promise<string>
(function () {
  "use strict";

  function hasMiniAppBridge() {
    return !!(
      window.xm &&
      typeof window.xm.native === "function"
    );
  }

  function waitForBridge(options) {
    options = options || {};
    var timeoutMs = Number(options.timeoutMs || 12000);
    var intervalMs = Number(options.intervalMs || 120);
    var startedAt = Date.now();

    return new Promise(function (resolve) {
      function check() {
        if (hasMiniAppBridge()) {
          resolve(true);
          return;
        }

        if (Date.now() - startedAt >= timeoutMs) {
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
      data = JSON.parse(response);
    }

    if (data && typeof data.token === "string" && data.token.length > 0) {
      return data.token;
    }

    throw new Error("getMiniAppToken response did not contain token");
  }

  function getMiniAppToken(appId) {
    if (!hasMiniAppBridge()) {
      return Promise.reject(new Error("SuperApp bridge is unavailable"));
    }

    return window.xm
      .native("getMiniAppToken", { appId: appId })
      .then(readToken);
  }

  window.SuperAppBridge = {
    isAvailable: hasMiniAppBridge,
    waitForBridge: waitForBridge,
    getMiniAppToken: getMiniAppToken,
  };

  window.isSuperAppWebView = hasMiniAppBridge;
  window.getMiniAppToken = getMiniAppToken;
})();
