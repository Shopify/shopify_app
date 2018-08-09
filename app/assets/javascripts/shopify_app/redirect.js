document.addEventListener("DOMContentLoaded", function() {
  var redirectTargetElement = document.getElementById("redirection-target");
  var targetInfo = JSON.parse(redirectTargetElement.dataset.target);

  function redirect() {
    window.top.location.href = targetInfo.url;
  }

  if (window.top == window.self) {
    // If Storage Access API is available, generate UI for user to interact with to trigger cookie partitioning

    var isSafari = window.navigator.userAgent.indexOf('Safari');
    var versionNumber;
    
    if (isSafari) {
      versionNumber = parseFloat(window.navigator.userAgent.match(/Version\/(\d+\.?\d*)/)[1]);
    }

    // TODO: Replace user agent checking with library
    if (!document.hasStorageAccess || !isSafari || versionNumber < 12) {
      redirect();
      return;
    }

    var button = document.createElement('button');
    button.innerHTML = 'Request Storage Access';
    button.addEventListener('click', redirect);
    document.body.appendChild(button);

  } else {
    // If the current window is the 'child', change the parent's URL with postMessage
    normalizedLink = document.createElement('a');
    normalizedLink.href = targetInfo.url;

    data = JSON.stringify({
      message: 'Shopify.API.remoteRedirect',
      data: { location: normalizedLink.href }
    });
    window.parent.postMessage(data, targetInfo.myshopifyUrl);
  }
});
