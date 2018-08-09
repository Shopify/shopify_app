function shouldTriggerCookiePartitioning() {
  var userAgent =  window.navigator.userAgent;
  var isSafari = userAgent.indexOf('Safari');
  var versionNumber = isSafari ? parseFloat(userAgent.match(/Version\/(\d+\.?\d*)/)[1]) : null;
  
  // TODO: Replace with library for checking user-agents
  return document.hasStorageAccess && isSafari && versionNumber >= 12;
}