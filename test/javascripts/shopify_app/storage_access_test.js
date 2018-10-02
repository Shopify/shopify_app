suite('StorageAccessHelper', () => { 
  let storageAccessHelper;
  const redirectInfoStub = {
    hasStorageAccessUrl: 'https://hasStorageAccess.com',
    doesNotHaveStorageAccessUrl: 'https://doesNotHaveStorageAccess.com',
    myShopifyUrl: 'https://shop1.myshopify.io',
    home: 'https://app.io',
  };

  let contentContainer;
  let button;
  let redirectToEmbeddedStub;

  setup(() => {
    window.parent.postMessage = sinon.stub();

    contentContainer = document.createElement('div');
    button = document.createElement('button');

    contentContainer.setAttribute('id', 'RequestStorageAccess');
    button.setAttribute('id', 'TriggerAllowCookiesPrompt');
    button.setAttribute('type', 'button');

    contentContainer.appendChild(button);
    document.body.appendChild(contentContainer);
    storageAccessHelper = new StorageAccessHelper(redirectInfoStub);
    redirectToEmbeddedStub = sinon.stub(ITPHelper.prototype, 'redirectToEmbedded');
  });

  teardown(() => {
    document.body.removeChild(contentContainer);
    redirectToEmbeddedStub.restore();
  });

  suite('execute', () => {
    test('calls redirectToAppHome instead of manageStorageAccess if ITPHelper.userAgentIsAffected returns true', async () => {
      var userAgentIsAffectedStub = sinon.stub(ITPHelper.prototype, 'userAgentIsAffected').callsFake(() => false);

      const manageStorageAccessStub = sinon.stub(storageAccessHelper, 'manageStorageAccess').callsFake(() => true);

      const redirectToAppHomeStub = sinon.stub(storageAccessHelper, 'redirectToAppHome');

      storageAccessHelper.execute();

      sinon.assert.notCalled(manageStorageAccessStub);
      sinon.assert.called(redirectToAppHomeStub);

      userAgentIsAffectedStub.restore();
      manageStorageAccessStub.restore();
      redirectToAppHomeStub.restore();
    });

    test('calls manageStorageAccess instead of redirectToAppHome if ITPHelper.userAgentIsAffected returns true', async () => {
      var userAgentIsAffectedStub = sinon.stub(ITPHelper.prototype, 'userAgentIsAffected').callsFake(() => true);

      const manageStorageAccessStub = sinon.stub(storageAccessHelper, 'manageStorageAccess').callsFake(() => true);

      const redirectToAppHomeStub = sinon.stub(storageAccessHelper, 'redirectToAppHome');

      storageAccessHelper.execute();

      sinon.assert.called(manageStorageAccessStub);
      sinon.assert.notCalled(redirectToAppHomeStub);

      userAgentIsAffectedStub.restore();
      manageStorageAccessStub.restore();
      redirectToAppHomeStub.restore();
    });
  });

  suite('manageStorageAccess', () => {
    test('calls handleHasStorageAccess instead of handleGetStorageAccess if document.hasStorageAccess returns true', async () => {
      document.hasStorageAccess = () => {
        return new Promise((resolve) => {
          resolve(true);
        });
      };

      const handleGetStorageAccessSpy = sinon.stub(storageAccessHelper, 'handleGetStorageAccess');
      const handleHasStorageAccessSpy = sinon.stub(storageAccessHelper, 'handleHasStorageAccess');

      storageAccessHelper.manageStorageAccess().then(() => {
        sinon.assert.called(handleHasStorageAccessSpy);
        sinon.assert.notCalled(handleGetStorageAccessSpy);

        handleHasStorageAccessSpy.restore();
        handleGetStorageAccessSpy.restore();
      });
    });

    test('calls handleGetStorageAccess instead of handleHasStorageAccess if document.hasStorageAccess returns false', async () => {
      document.hasStorageAccess = () => {
        return new Promise((resolve) => {
          resolve(false);
        });
      };

      const handleGetStorageAccessSpy = sinon.stub(storageAccessHelper, 'handleGetStorageAccess');
      const handleHasStorageAccessSpy = sinon.stub(storageAccessHelper, 'handleHasStorageAccess');

      storageAccessHelper.manageStorageAccess().then(() => { 
        sinon.assert.called(handleGetStorageAccessSpy);
        sinon.assert.notCalled(handleHasStorageAccessSpy);

        handleHasStorageAccessSpy.restore();
        handleGetStorageAccessSpy.restore();
      });
    });
  });

  suite('handleGetStorageAccess', () => {
    test('calls setupRequestStorageAccess instead of redirectToAppTLD if shopify.has_redirected is defined in sessionStorage', () => {
      const setupRequestStorageAccessSpy = sinon.stub(storageAccessHelper, 'setupRequestStorageAccess');
      const redirectToAppTLDSpy = sinon.stub(storageAccessHelper, 'redirectToAppTLD');

      sessionStorage.setItem('shopify.has_redirected', 'true');

      storageAccessHelper.handleGetStorageAccess();

      sinon.assert.called(setupRequestStorageAccessSpy);
      sinon.assert.notCalled(redirectToAppTLDSpy);

      setupRequestStorageAccessSpy.restore();
      redirectToAppTLDSpy.restore();
    });

    test('calls redirectToAppTLD instead of setupRequestStorageAccess if shopify.has_redirected is defined in sessionStorage', () => {
      const setupRequestStorageAccessSpy = sinon.stub(storageAccessHelper, 'setupRequestStorageAccess');
      const redirectToAppTLDSpy = sinon.stub(storageAccessHelper, 'redirectToAppTLD');

      sessionStorage.removeItem('shopify.has_redirected');

      storageAccessHelper.handleGetStorageAccess();

      sinon.assert.notCalled(setupRequestStorageAccessSpy);
      sinon.assert.called(redirectToAppTLDSpy);

      setupRequestStorageAccessSpy.restore();
      redirectToAppTLDSpy.restore();
    });
  });

  suite('setupRequestStorageAccess', () => {
    test('adds an event listener to the expected button that calls requestStorageAccess on click', () => {
      document.requestStorageAccess = () => {
        return new Promise((resolve) => {
          resolve(true);
        });
      };

      const handleRequestStorageAccessSpy = sinon.spy(storageAccessHelper, 'handleRequestStorageAccess');

      storageAccessHelper.setupRequestStorageAccess();
      button = document.querySelector('#TriggerAllowCookiesPrompt');
      button.click();

      sinon.assert.called(handleRequestStorageAccessSpy);
      handleRequestStorageAccessSpy.restore();
    });

    test('sets display property of the expected node to "block"', () => {
      storageAccessHelper.setupRequestStorageAccess();
      contentContainer = document.querySelector('#RequestStorageAccess');
      sinon.assert.match(contentContainer.style.display, 'block');
    });
  });

  suite('handleRequestStorageAccess', () => {
    test('calls redirectToAppHome instead of redirectToAppTLD when document.requestStorageAccess resolves', () => {
      document.requestStorageAccess = () => {
        return new Promise((resolve) => {
          resolve();
        });
      };

      const redirectToAppHomeStub = sinon.stub(storageAccessHelper, 'redirectToAppHome');
      const redirectToAppTLDStub = sinon.stub(storageAccessHelper, 'redirectToAppTLD');

      storageAccessHelper.handleRequestStorageAccess().then(() => {
        sinon.assert.called(redirectToAppHomeStub);
        sinon.assert.notCalled(redirectToAppTLDStub);

        redirectToAppHomeStub.restore();
        redirectToAppTLDStub.restore();
      });
    });

    test('calls redirectToAppTLD with "access denied" instead of calling redirectToAppHome when document.requestStorageAccess fails', () => {
      document.requestStorageAccess = () => {
        return new Promise((resolve, reject) => {
          reject();
        });
      };

      const redirectToAppHomeStub = sinon.stub(storageAccessHelper, 'redirectToAppHome');
      const redirectToAppTLDStub = sinon.stub(storageAccessHelper, 'redirectToAppTLD');

      storageAccessHelper.handleRequestStorageAccess().then(() => {
        sinon.assert.notCalled(redirectToAppHomeStub);
        sinon.assert.calledWith(redirectToAppTLDStub, 'access denied');

        redirectToAppHomeStub.restore();
        redirectToAppTLDStub.restore();
      });
    });
  });

  suite('redirectToAppHome', () => {
    test('sets "shopify.granted_storage_access" in sessionStorage', () => {
      storageAccessHelper.redirectToAppHome();
      sinon.assert.match(sessionStorage.getItem('shopify.granted_storage_access'), 'true');
    });
  });

  suite('redirectToAppTLD', () => {
    test('sets "shopify.has_redirected" in sessionStorage', () => {
      storageAccessHelper.redirectToAppTLD();
      sinon.assert.match(sessionStorage.getItem('shopify.has_redirected'), 'true');
    });
  });

  suite('setNormalizedLink', () => {
    test('returns redirectInfo.hasStorageAccessUrl if storage access is granted', () => {
      const link = storageAccessHelper.setNormalizedLink('access granted');
      sinon.assert.match(link, redirectInfoStub.hasStorageAccessUrl);
    });

    test('returns redirectInfo.doesNotHaveStorageAccessUrl if storage access is denied', () => {
      const link = storageAccessHelper.setNormalizedLink('access denied');
      sinon.assert.match(link, redirectInfoStub.doesNotHaveStorageAccessUrl);
    });
  });
});
