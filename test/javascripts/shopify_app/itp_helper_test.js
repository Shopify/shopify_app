suite('ITPHelper', () => {
  const ITPHelperSandbox = sinon.createSandbox();
  let contentContainer;
  let button;

  setup(() => {
    contentContainer = document.createElement('div');
    button = document.createElement('button');

    contentContainer.setAttribute('id', 'TopLevelInteractionContent');
    button.setAttribute('id', 'TopLevelInteractionButton');
    button.setAttribute('type', 'button');

    contentContainer.appendChild(button);
    document.body.appendChild(contentContainer);
    ITPHelperSandbox.stub(ITPHelper.prototype, 'redirect');
    window.onbeforeunload = () => 'Oh no!';
  });

  teardown(() => {
    document.body.removeChild(contentContainer);
    ITPHelperSandbox.restore();
  });

  suite('userAgentIsAffected', () => {
    test('returns false if document.hasStorageAccess is undefined', () => {
      navigator.__defineGetter__('userAgent', function(){
        return '';
      });

      document.hasStorageAccess = undefined;

      sinon.assert.match(ITPHelper.prototype.userAgentIsAffected(), false);
    });

    test('returns true if document.hasStorageAccess is defined', () => {
      navigator.__defineGetter__('userAgent', function(){
        return '';
      });

      document.hasStorageAccess = function() {
        return true;
      }

      sinon.assert.match(ITPHelper.prototype.userAgentIsAffected(), true);
    });
  });

  suite('canPartitionCookies', () => {
    test('returns true if the user agent is a version of Safari 12.0', () => {
      navigator.__defineGetter__('userAgent', function(){
        return 'Version/12.0 Safari';
      });

      sinon.assert.match(ITPHelper.prototype.canPartitionCookies(), true);

      navigator.__defineGetter__('userAgent', function(){
        return 'Version/12.0.1 Safari';
      });

      sinon.assert.match(ITPHelper.prototype.canPartitionCookies(), true);
    });

    test('returns false if the user agent is a version of Safari 12.0', () => {
      navigator.__defineGetter__('userAgent', function(){
        return 'Version/12.1 Safari';
      });

      sinon.assert.match(ITPHelper.prototype.canPartitionCookies(), false);

      navigator.__defineGetter__('userAgent', function(){
        return 'Version/12.1.2 Safari';
      });

      sinon.assert.match(ITPHelper.prototype.canPartitionCookies(), false);

      navigator.__defineGetter__('userAgent', function(){
        return 'Version/11.0 Safari';
      });

      sinon.assert.match(ITPHelper.prototype.canPartitionCookies(), false);
    });
  });

  suite('setUpContent', () => {
    test('adds an event listener to the #TopLevelInteractionButton node that calls redirect on click', () => {
      const helper = new ITPHelper({
        redirectUrl: 'https://test',
      });

      helper.setUpContent();

      button = document.querySelector('#TopLevelInteractionButton');
      button.click();

      sinon.assert.called(ITPHelper.prototype.redirect);
    });

    test('sets display property of the #TopLevelInteractionContent node to "block"', () => {
      const helper = new ITPHelper({
        redirectUrl: 'https://test',
      });

      helper.setUpContent();
      contentContainer = document.querySelector('#TopLevelInteractionContent');
      sinon.assert.match(contentContainer.style.display, 'block');
    });
  });
});
