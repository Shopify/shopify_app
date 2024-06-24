const { assert } = require("chai");

suite('appBridgeRedirect', () => {
  const sandbox = sinon.createSandbox();
  const url = '/settings';

  teardown(() => {
    sandbox.restore();
  });

  test('calls App Bridge redirect to normalized url', () => {
    const open = sinon.spy();
    sandbox.stub(window, 'open').callsFake(open);

    appBridgeRedirect(url);

    assert(open.calledOnce);
    assert.match(open.lastCall.args[0], new RegExp(`${url}$`));
    assert.equal(open.lastCall.args[1], '_top');
  });
});
