suite('sessionToken', () => {
  const sandbox = sinon.createSandbox();
  const url = '/settings';

  setup(() => {
    window['app-bridge'] = {
      default() {},
      actions: {
        SessionToken: {
          request() {
            return {
              REQUEST: 'SESSION_TOKEN::REQUEST',
            };
          },
        },
      },
    };
    window.apiKey = '123';
    window.shopOrigin = "https://myshop.com";
  });

  teardown(() => {
    sandbox.restore();
    delete window['app-bridge'];
  });


  test('calls App Bridge to create an app with the apiKey and shopOrigin from window', () => {
    var createApp = sinon.spy();
    sinon.stub(window['app-bridge'], 'default').callsFake(createApp);

    appBridgeFetchSessionToken();

    sinon.assert.calledWith(createApp, {
      apiKey: window.apiKey,
      shopOrigin: 'myshop.com',
    });
  });

  test('calls to dispatch a SESSION_TOKEN::REQUEST action when sessionToken is currently nonexistent', () => {
    const AppBridge = window['app-bridge'];
    const SessionToken = AppBridge.actions.SessionToken;
     var mockApp = {
       dispatch: sinon.spy(),
    };
    sinon.stub(AppBridge, 'default').callsFake(() => mockApp);
    sinon.stub(SessionToken, 'request').callsFake(() => {});

    appBridgeFetchSessionToken();

    sinon.assert.called(SessionToken.request);
  });

  test('returns pre-existing session token if valid', () => {
    window['sessionToken'] = 'validSessionToken';
    const AppBridge = window['app-bridge'];
    const SessionToken = AppBridge.actions.SessionToken;
    var mockApp = {
      dispatch: sinon.spy(),
    };
    sinon.stub(AppBridge, 'default').callsFake(() => mockApp);
    sinon.stub(SessionToken, 'request').callsFake(() => {});

    appBridgeFetchSessionToken();

    sinon.assert.notCalled(SessionToken.request);
  });

  test('calls to dispatch a SESSION_TOKEN::REQUEST action when current token is expired', () => {
    window['sessionToken'] = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXSyIsImN0eSI6IkpXSyJ9.eyJpc3MiOiJodHRwczovL3Nob3AxLm15c2hvcGlmeS5pby9hZG1pbiIsImF1ZCI6ImRldmVsb3BtZW50LXdpZGdldC1rZXkiLCJzdWIiOiIxIiwiZXhwIjoxMDgwNjgwNjAwLCJuYmYiOjE1ODU2ODI2MDQsImlhdCI6MTA4MDY4MDYwMCwianRpIjoiYjkwYzJhOTgtYjQyMC00MDVjLTgwZDktNmY0OTlhMWFkNzY3In0.KWW0UGDvcIeScJRpjIncPhjswlnGzHsY2AAI6ITugNU';
    const AppBridge = window['app-bridge'];
    const SessionToken = AppBridge.actions.SessionToken;
    var mockApp = {
      dispatch: sinon.spy(),
    };
    sinon.stub(AppBridge, 'default').callsFake(() => mockApp);
    sinon.stub(SessionToken, 'request').callsFake(() => {});

    appBridgeFetchSessionToken();

    sinon.assert.called(SessionToken.request);
  });

  // test('calls to dispatch a remote redirect App Bridge action with the url normalized to be relative to the window origin', () => {
  //   const AppBridge = window['app-bridge'];
  //   const Redirect = AppBridge.actions.Redirect;
  //   var mockApp = {};
  //   var RedirectInstance = {
  //     dispatch: sinon.spy(),
  //   };
  //   sinon.stub(AppBridge, 'default').callsFake(() => mockApp);
  //   sinon.stub(Redirect, 'create').callsFake(() => RedirectInstance);
  //
  //   const normalizedUrl = `${window.location.origin}${url}`;
  //
  //   appBridgeRedirect(url);
  //
  //   sinon.assert.calledWith(Redirect.create, mockApp);
  //   sinon.assert.calledWith(
  //     RedirectInstance.dispatch,
  //     'REDIRECT::REMOTE',
  //     normalizedUrl
  //   );
  // });
});
