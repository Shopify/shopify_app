suite('partition_cookies', () => {
  let contentContainer;
  let button;
  let redirectToEmbeddedStub;
  let setUpContentSpy;
  let redirectStub;
  let setCookiesPersistStub;
  let userAgentIsAffectedStub;

  setup(() => {
    contentContainer = document.createElement('div');
    button = document.createElement('button');

    contentContainer.setAttribute('id', 'CookiePartitionPrompt');
    button.setAttribute('id', 'AcceptCookies');
    button.setAttribute('type', 'button');

    contentContainer.appendChild(button);
    document.body.appendChild(contentContainer);

    redirectToEmbeddedStub = sinon.stub(ITPHelper.prototype, 'redirectToEmbedded');
    setUpContentSpy = sinon.spy(ITPHelper.prototype, 'setUpContent');
    userAgentIsAffectedStub = sinon.stub(ITPHelper.prototype, 'userAgentIsAffected')
    redirectStub = sinon.stub();
  });

  teardown(() => {
    document.body.removeChild(contentContainer);
    redirectToEmbeddedStub.restore();
    setUpContentSpy.restore();
    setCookiesPersistStub.restore();
    userAgentIsAffectedStub.restore();
  });

  suite('setUpPartitionCookies', () => {
    test('it calls setUpContent instead of calling setCookiesPersist and the given redirect function if the user agent is affected by ITP', () => {
      userAgentIsAffectedStub.callsFake(() => {
        return true;
      });

      setUpPartitionCookies(redirectStub);
      setCookiesPersistStub = sinon.stub(PartitionCookies, 'setCookiesPersist');

      sinon.assert.called(setUpContentSpy);
      sinon.assert.notCalled(setCookiesPersistStub);
      sinon.assert.notCalled(redirectStub);
    });

    test('it calls setCookiesPersist and the given redirect function instead of setUpContent calling  if the user agent is affected by ITP', () => {
      userAgentIsAffectedStub.callsFake(() => {
        return false;
      });

      setCookiesPersistStub = sinon.stub(PartitionCookies, 'setCookiesPersist');

      setUpPartitionCookies(redirectStub);
      

      sinon.assert.notCalled(setUpContentSpy);
      sinon.assert.called(setCookiesPersistStub);
      sinon.assert.called(redirectStub);
    });
  });
});
