function shouldTriggerCookiePartitioning() {
  var userAgent =  window.navigator.userAgent;
  var isSafari = userAgent.indexOf('Safari');
  var versionNumber = isSafari ? parseFloat(userAgent.match(/Version\/(\d+\.?\d*)/)[1]) : null;
  
  // TODO: Replace with library for checking user-agents
  return document.hasStorageAccess && isSafari && versionNumber >= 12;
}

function setCookieandRedirect() {
  document.cookie = "shopify.partition_cookies=true";
  redirectToEmbedded()
}

document.addEventListener("DOMContentLoaded", function() {
  function redirect() {
    window.top.location.href = targetInfo.url;
  }

  if (window.top == window.self) {
    if (!shouldTriggerCookiePartitioning()) {
      redirectToEmbedded();
      return;
    }

    var button = document.createElement('button');
    button.innerHTML = 'Allow third-party cookies';
    button.addEventListener('click', setCookieandRedirect);
    document.body.appendChild(button);
  } else {
    // TODO: Redirect to home?
  }
});
