suite('redirect', () => {
  const redirectHelperSandbox = sinon.createSandbox();

  let contentContainer;
  let url = '/settings';

  setup(() => {
    contentContainer = document.createElement('div');

    contentContainer.setAttribute('id', 'redirection-target');
    contentContainer.dataset['target'] = JSON.stringify({url});
    document.body.appendChild(contentContainer);

    redirectHelperSandbox.stub(window, 'appBridgeRedirect').callsFake(() => {});
  });

  teardown(() => {
    redirectHelperSandbox.restore();
    document.body.removeChild(contentContainer);
  });

  test('calls appBridgeRedirect', () => {
    require('../../../app/assets/javascripts/shopify_app/redirect');
    sinon.assert.calledWith(window.appBridgeRedirect, url);
  });
});