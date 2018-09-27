function ITPHelper(selectors) {
  this.itpContent = document.querySelector(selectors.content);
  this.itpAction = document.querySelector(selectors.action);

  if (!this.itpContent) {
    return null;
  }
}

ITPHelper.prototype.redirectToEmbedded = function() {
  window.location.href = window.shopOrigin + "/admin/apps/" + window.apiKey;
}

ITPHelper.prototype.userAgentIsAffected = function() {
  if (navigator.userAgent.indexOf('com.jadedpixel.pos') !== -1) {
    return false;
  }

  if (navigator.userAgent.indexOf('Shopify Mobile/iOS') !== -1) {
    return false;
  }

  return Boolean(document.hasStorageAccess);
}

ITPHelper.prototype.setUpContent = function(onClick) {
  this.itpContent.style.display = 'block';
  this.itpAction.addEventListener('click', function() {
    if (onClick) {
      onClick();
    }

    this.redirectToEmbedded();
  }.bind(this));
}
