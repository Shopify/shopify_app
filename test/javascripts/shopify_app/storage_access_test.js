suite('StorageAccessHelper', () => {
  const storageAccessHelperSandbox = sinon.createSandbox();
  let storageAccessHelper;
  const redirectDataStub = {
    hasStorageAccessUrl: 'https://hasStorageAccess.com',
    doesNotHaveStorageAccessUrl: 'https://doesNotHaveStorageAccess.com',
    myShopifyUrl: 'https://shop1.myshopify.io',
    home: 'https://app.io',
  };

  let contentContainer;
  let button;

  setup(() => {
    storageAccessHelperSandbox.stub(window.parent, 'postMessage');

    contentContainer = document.createElement('div');
    button = document.createElement('button');

    contentContainer.setAttribute('id', 'RequestStorageAccess');
    button.setAttribute('id', 'TriggerAllowCookiesPrompt');
    button.setAttribute('type', 'button');

    contentContainer.appendChild(button);
    document.body.appendChild(contentContainer);
    storageAccessHelper = new StorageAccessHelper(redirectDataStub);
    storageAccessHelperSandbox.stub(ITPHelper.prototype, 'redirect');
  });

  teardown(() => {
    document.body.removeChild(contentContainer);
    storageAccessHelperSandbox.restore();
  });

  suite('execute', () => {
    test('calls setUpCookiePartitioning if ITPHelper.canPartitionCookies returns true', () => {
      storageAccessHelperSandbox.stub(ITPHelper.prototype, 'canPartitionCookies').callsFake(() => true);

      storageAccessHelperSandbox.stub(storageAccessHelper, 'setUpCookiePartitioning');

      storageAccessHelper.execute();

      sinon.assert.called(storageAccessHelper.setUpCookiePartitioning);
    });

    test('calls redirectToAppHome instead of manageStorageAccess or setUpCookiePartitioningStub if ITPHelper.userAgentIsAffected returns true', async () => {
      storageAccessHelperSandbox.stub(ITPHelper.prototype, 'userAgentIsAffected').callsFake(() => false);

      storageAccessHelperSandbox.stub(storageAccessHelper, 'manageStorageAccess').callsFake(() => true);

      storageAccessHelperSandbox.stub(storageAccessHelper, 'redirectToAppHome');
      storageAccessHelperSandbox.stub(storageAccessHelper, 'setUpCookiePartitioning');

      storageAccessHelper.execute();

      sinon.assert.notCalled(storageAccessHelper.manageStorageAccess);
      sinon.assert.called(storageAccessHelper.redirectToAppHome);
      sinon.assert.notCalled(storageAccessHelper.setUpCookiePartitioning);
    });

    test('calls manageStorageAccess instead of redirectToAppHome if ITPHelper.userAgentIsAffected returns true', async () => {
      storageAccessHelperSandbox.stub(ITPHelper.prototype, 'userAgentIsAffected').callsFake(() => true);

      storageAccessHelperSandbox.stub(storageAccessHelper, 'manageStorageAccess').callsFake(() => true);

      storageAccessHelperSandbox.stub(storageAccessHelper, 'redirectToAppHome');
      storageAccessHelperSandbox.stub(storageAccessHelper, 'setUpCookiePartitioning');

      storageAccessHelper.execute();

      sinon.assert.called(storageAccessHelper.manageStorageAccess);
      sinon.assert.notCalled(storageAccessHelper.redirectToAppHome);
      sinon.assert.notCalled(storageAccessHelper.setUpCookiePartitioning);
    });
  });

  suite('manageStorageAccess', () => {
    test('calls handleHasStorageAccess instead of handleGetStorageAccess if document.hasStorageAccess returns true', async () => {
      document.hasStorageAccess = () => {
        return new Promise((resolve) => {
          resolve(true);
        });
      };

      storageAccessHelperSandbox.stub(storageAccessHelper, 'handleGetStorageAccess');
      storageAccessHelperSandbox.stub(storageAccessHelper, 'handleHasStorageAccess');

      storageAccessHelper.manageStorageAccess().then(() => {
        sinon.assert.called(storageAccessHelper.handleHasStorageAccess);
        sinon.assert.notCalled(storageAccessHelper.handleGetStorageAccess);
      });
    });

    test('calls handleGetStorageAccess instead of handleHasStorageAccess if document.hasStorageAccess returns false', async () => {
      document.hasStorageAccess = () => {
        return new Promise((resolve) => {
          resolve(false);
        });
      };

      storageAccessHelperSandbox.stub(storageAccessHelper, 'handleGetStorageAccess');
      storageAccessHelperSandbox.stub(storageAccessHelper, 'handleHasStorageAccess');

      storageAccessHelper.manageStorageAccess().then(() => { 
        sinon.assert.called(storageAccessHelper.handleGetStorageAccess);
        sinon.assert.notCalled(storageAccessHelper.handleHasStorageAccess);
      });
    });
  });

  suite('handleGetStorageAccess', () => {
    test('calls setupRequestStorageAccess instead of redirectToAppTLD if shopify.top_level_interaction is defined in sessionStorage', () => {
      storageAccessHelperSandbox.stub(storageAccessHelper, 'setupRequestStorageAccess');
      storageAccessHelperSandbox.stub(storageAccessHelper, 'redirectToAppTLD');

      sessionStorage.setItem('shopify.top_level_interaction', 'true');

      storageAccessHelper.handleGetStorageAccess();

      sinon.assert.called(storageAccessHelper.setupRequestStorageAccess);
      sinon.assert.notCalled(storageAccessHelper.redirectToAppTLD);
    });

    test('calls redirectToAppTLD instead of setupRequestStorageAccess if shopify.top_level_interaction is defined in sessionStorage', () => {
      storageAccessHelperSandbox.stub(storageAccessHelper, 'setupRequestStorageAccess');
      storageAccessHelperSandbox.stub(storageAccessHelper, 'redirectToAppTLD');

      sessionStorage.removeItem('shopify.top_level_interaction');

      storageAccessHelper.handleGetStorageAccess();

      sinon.assert.notCalled(storageAccessHelper.setupRequestStorageAccess);
      sinon.assert.called(storageAccessHelper.redirectToAppTLD);
    });
  });

  suite('setupRequestStorageAccess', () => {
    test('adds an event listener to the expected button that calls requestStorageAccess on click', () => {
      document.requestStorageAccess = () => {
        return new Promise((resolve) => {
          resolve(true);
        });
      };

      storageAccessHelperSandbox.spy(storageAccessHelper, 'handleRequestStorageAccess');

      storageAccessHelper.setupRequestStorageAccess();
      button = document.querySelector('#TriggerAllowCookiesPrompt');
      button.click();

      sinon.assert.called(storageAccessHelper.handleRequestStorageAccess);
    });

    test('sets display property of the expected node to "block"', () => {
      storageAccessHelper.setupRequestStorageAccess();
      contentContainer = document.querySelector('#RequestStorageAccess');
      sinon.assert.match(contentContainer.style.display, 'block');
    });
  });

  suite('handleRequestStorageAccess', () => {
    test('calls redirectToAppHome instead of redirectToAppsIndex when document.requestStorageAccess resolves', () => {
      document.requestStorageAccess = () => {
        return new Promise((resolve) => {
          resolve();
        });
      };

      storageAccessHelperSandbox.stub(storageAccessHelper, 'redirectToAppHome');
      storageAccessHelperSandbox.stub(storageAccessHelper, 'redirectToAppsIndex');

      storageAccessHelper.handleRequestStorageAccess().then(() => {
        sinon.assert.called(storageAccessHelper.redirectToAppHome);
        sinon.assert.notCalled(storageAccessHelper.redirectToAppsIndex);
      });
    });

    test('calls redirectToAppsIndex with "storage_access_denied" instead of calling redirectToAppHome when document.requestStorageAccess fails', () => {
      document.requestStorageAccess = () => {
        return new Promise((resolve, reject) => {
          reject();
        });
      };

      storageAccessHelperSandbox.stub(storageAccessHelper, 'redirectToAppHome');
      storageAccessHelperSandbox.stub(storageAccessHelper, 'redirectToAppsIndex');

      storageAccessHelper.handleRequestStorageAccess().then(() => {
        sinon.assert.notCalled(storageAccessHelper.redirectToAppHome);
        sinon.assert.calledWith(storageAccessHelper.redirectToAppsIndex, 'storage_access_denied');
      });
    });
  });

  suite('redirectToAppHome', () => {
    test('sets "shopify.granted_storage_access" in sessionStorage', () => {
      storageAccessHelper.redirectToAppHome();
      sinon.assert.match(sessionStorage.getItem('shopify.granted_storage_access'), 'true');
    });
  });

  suite('setNormalizedLink', () => {
    test('returns redirectData.hasStorageAccessUrl if storage access is granted', () => {
      const link = storageAccessHelper.setNormalizedLink('storage_access_granted');
      sinon.assert.match(link, redirectDataStub.hasStorageAccessUrl);
    });

    test('returns redirectData.doesNotHaveStorageAccessUrl if storage access is denied', () => {
      const link = storageAccessHelper.setNormalizedLink('storage_access_denied');
      sinon.assert.match(link, redirectDataStub.doesNotHaveStorageAccessUrl);
    });
  });

  suite('setUpCookiePartitioning', () => {
    test('sets the display property of the #CookiePartitionPrompt node to "block"', () => {
      const node = document.createElement('div');
      node.id = 'CookiePartitionPrompt';
      node.style.display = 'none';

      const button = document.createElement('button');
      button.type = 'button';
      button.id = 'AcceptCookies';
      
      node.appendChild(button);
      document.body.appendChild(node);

      storageAccessHelper.setUpCookiePartitioning();

      sinon.assert.match(node.style.display, 'block');

      document.body.removeChild(node);
    });

    test('adds an event listener to the #AcceptCookies button that calls setCookieAndRedirect on click', () => {
      const node = document.createElement('div');
      node.id = 'CookiePartitionPrompt';
      node.style.display = 'none';

      const button = document.createElement('button');
      button.type = 'button';
      button.id = 'AcceptCookies';
      
      node.appendChild(button);
      document.body.appendChild(node);

      storageAccessHelperSandbox.stub(storageAccessHelper, 'setCookieAndRedirect');

      storageAccessHelper.setUpCookiePartitioning();

      button.click();
      sinon.assert.called(storageAccessHelper.setCookieAndRedirect);

      document.body.removeChild(node);
    });
  });
  
  suite('setCookieAndRedirect', () => {
    test('sets the shopify.cookies_persist cookie', () => {
      storageAccessHelper.setCookieAndRedirect();
      sinon.assert.match(document.cookie.match('shopify.cookies_persist').length, 1);
    });
  });

  suite('setUpHelper', () => {
    test('passes the correct redirectUrl to the ITPHelper constructor', () => {
      window.shopOrigin = 'https://test-shop.myshopify.io';
      window.apiKey = '123';
      
      const itpHelper = storageAccessHelper.setUpHelper();
      sinon.assert.match(itpHelper.redirectUrl, 'https://test-shop.myshopify.io/admin/apps/123');
    })
  });
});
