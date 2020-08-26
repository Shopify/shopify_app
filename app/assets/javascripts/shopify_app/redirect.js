(function() {
  function redirect() {
    var redirectTargetElement = document.getElementById("redirection-target");

    if (!redirectTargetElement) {
      return;
    }

    var targetInfo = JSON.parse(redirectTargetElement.dataset.target)

    if (window.top == window.self) {
      // If the current window is the 'parent', change the URL by setting location.href
      window.top.location.href = targetInfo.url;
    } else {
      // If the current window is the 'child', change the parent's URL with postMessage
      normalizedLink = document.createElement('a');
      normalizedLink.href = targetInfo.url;

      data = JSON.stringify({
        message: 'Shopify.API.remoteRedirect',
        data: {location: normalizedLink.href}
      });
      window.parent.postMessage(data, targetInfo.myshopifyUrl);
    }
  }

  document.addEventListener("DOMContentLoaded", redirect);

  // In the turbolinks context, neither DOMContentLoaded nor turbolinks:load
  // consistently fires. This ensures that we at least attempt to fire in the
  // turbolinks situation as well.
  redirect();
})();
