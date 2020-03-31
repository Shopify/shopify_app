(function () {
  const isValidToken = (sessionToken) => {
    console.log(jwtDecode(sessionToken));
    return jwtDecode(sessionToken).exp > Math.floor(Date.now() / 1000);
  };

  async function appBridgeFetchSessionToken() {
    var AppBridge = window['app-bridge'];
    var createApp = AppBridge.default;
    var SessionToken = AppBridge.actions.SessionToken;
    var app  = createApp({
      apiKey: window.apiKey,
      shopOrigin: window.shopOrigin.replace(/^https:\/\//, ''),
    });

    const sessionToken = window.sessionToken;
    if (sessionToken && isValidToken(sessionToken)) {
      return sessionToken;
    }

    app.dispatch(SessionToken.request());

    const unsubscribe = await app.subscribe(SessionToken.ActionType.RESPOND, (payload) => {
      console.log('Session token: ', payload.sessionToken);
      unsubscribe();
    });
  }

  this.appBridgeFetchSessionToken = appBridgeFetchSessionToken;
})(window);
