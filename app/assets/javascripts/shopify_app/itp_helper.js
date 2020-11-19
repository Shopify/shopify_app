(function() {
  function ITPHelper(opts) {
    this.itpContent = document.getElementById('TopLevelInteractionContent');
    this.itpAction = document.getElementById('TopLevelInteractionButton');
    this.redirectUrl = opts.redirectUrl;
  }

  // ITPHelper.prototype.redirect = function() {
  //   sessionStorage.setItem('shopify.top_level_interaction', true);
  //   window.location.href = this.redirectUrl;
  // }

  ITPHelper.prototype.userAgentIsAffected = function() {
    return Boolean(document.hasStorageAccess);
  }

  ITPHelper.prototype.canPartitionCookies = function() {
    var versionRegEx = /Version\/12\.0\.?\d? Safari/;
    return versionRegEx.test(navigator.userAgent);
  }

  ITPHelper.prototype.setUpContent = function(onClick) {
    this.itpContent.style.display = 'block';
    this.itpAction.addEventListener('click', this.redirect.bind(this));
  }

  ITPHelper.prototype.execute = function() {
    if (!this.itpContent) {
      return;
    }

    if (this.userAgentIsAffected()) {
      this.setUpContent();
    } else {
      this.redirect();
    }
  }

  this.ITPHelper = ITPHelper;
})(window);
