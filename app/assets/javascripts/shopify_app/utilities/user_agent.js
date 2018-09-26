function UserAgentUtilities() {
  this.userAgent = navigator.userAgent;
}

UserAgentUtilities.prototype.shouldRenderITPContent = function() {
  if (this.userAgent.indexOf('com.jadedpixel.pos') !== -1) {
    return false;
  }

  if (this.userAgent.indexOf('Shopify Mobile/iOS') !== -1) {
    return false;
  }

  return Boolean(document.hasStorageAccess);
}