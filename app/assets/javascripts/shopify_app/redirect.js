(function() {
  function redirect() {
    var redirectTargetElement = document.getElementById("redirection-target");

    if (!redirectTargetElement) {
      return;
    }

    var targetInfo = JSON.parse(redirectTargetElement.dataset.target)

    function redirectViaPostMessage() {
      normalizedLink = document.createElement('a');
      normalizedLink.href = targetInfo.url;

      data = JSON.stringify({
        message: 'Shopify.API.remoteRedirect',
        data: {location: normalizedLink.href}
      });
      window.parent.postMessage(data, targetInfo.myshopifyUrl);
    }

    if (window.top == window.self) {
      // If the current window is the 'parent', change the URL by setting location.href
      window.top.location.href = targetInfo.url;
    } else {
      // If the current window is the 'child', change the parent's URL with postMessage
      document.hasStorageAccess().then((hasAccess) => {
        if (hasAccess) {
          // Can't get this to be true in the iframe
          redirectViaPostMessage();
        } else {
          // How can we tell if we need to request for storage access or not?
          const requestButton = document.createElement('button');
          requestButton.innerHTML = 'Give me access';
          requestButton.addEventListener('click', () => {
            document.requestStorageAccess().then(() => {
              redirectViaPostMessage();
            }, () => {
              // needed for first redirect, if user has not interacted with TLD
              redirectViaPostMessage();
            });
          });
    
          document.body.appendChild(requestButton);
        }
      });
    }
  }

  document.addEventListener("DOMContentLoaded", redirect);

  // In the turbolinks context, neither DOMContentLoaded nor turbolinks:load
  // consistently fires. This ensures that we at least attempt to fire in the
  // turbolinks situation as well.
  redirect();
})();
