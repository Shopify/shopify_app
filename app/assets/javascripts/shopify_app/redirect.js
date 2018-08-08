document.addEventListener("DOMContentLoaded", function() {
  var redirectTargetElement = document.getElementById("redirection-target");
  var targetInfo = JSON.parse(redirectTargetElement.dataset.target);

  // If the current window is the 'parent', change the URL by setting location.href
  function redirect() {
    window.top.location.href = targetInfo.url;
  }

  // Feature detect
  // User interaction on the TLD
  // Set a cookie? (if not already)
  // Redirect to embedded
  if (window.top == window.self) {
    if (document.hasStorageAccess) {
      const button = document.createElement('button');
      button.value = 'Request Storage Access';
      button.addEventListener('click', redirect);
      document.body.appendChild(button);
      return;
    }

    redirect();   
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
