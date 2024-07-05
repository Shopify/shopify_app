const { assert } = require("chai");

suite('redirect', () => {
  const sandbox = sinon.createSandbox();
  const open = sinon.spy();
  let contentContainer;
  let url = '/settings';

  setup(() => {
    contentContainer = document.createElement('div');

    contentContainer.setAttribute('id', 'redirection-target');
    contentContainer.dataset['target'] = JSON.stringify({url});
    document.body.appendChild(contentContainer);
    sandbox.stub(window, 'open').callsFake(open);
  });

  teardown(() => {
    sandbox.restore();
    document.body.removeChild(contentContainer);
  });

  test('opens redirect url', () => {
    require('../../../app/assets/javascripts/shopify_app/redirect');

    assert(open.calledOnce);
    assert.match(open.lastCall.args[0], new RegExp(`${url}$`));
    assert.equal(open.lastCall.args[1], '_top');
  });
});
