(function() {
  function redirect() {
    var redirectTargetElement = document.getElementById("redirection-target");

    if (!redirectTargetElement) {
      return;
    }

    var targetInfo = JSON.parse(redirectTargetElement.dataset.target)

    function redirectViaPostMessage() {
      // needed for first redirect, if merchant has not interacted with TLD
      var normalizedLink = document.createElement('a');
      normalizedLink.href = targetInfo.url;

      data = JSON.stringify({
        message: 'Shopify.API.remoteRedirect',
        data: {location: normalizedLink.href}
      });
      window.parent.postMessage(data, targetInfo.myshopifyUrl);
      sessionStorage.setItem('shopify.has_redirected', 'true');
    }

    function redirectToAppHome() {
      window.location.href = targetInfo.home;
    }

    if (window.top == window.self) {
      // If the current window is the 'parent', change the URL by setting location.href
      window.top.location.href = targetInfo.url;
    } else {
      // If the current window is the 'child', check if child has storage access.
      // If request for storage access is rejected, change the parent's URL with postMessage.
      // If storage access is granted, redirect child to app home page
      document.hasStorageAccess().then((hasAccess) => {
        if (hasAccess) {
          redirectToAppHome();
        } else if (!sessionStorage.getItem('shopify.has_redirected')) {
          redirectViaPostMessage();
        } else {
          window.location.href = targetInfo.requestStorageAccess;
          // const requestButton = document.createElement('button');
          // requestButton.innerHTML = 'Give me access';
          // requestButton.addEventListener('click', () => {
          //   document.requestStorageAccess().then(redirectToAppHome, redirectViaPostMessage);
          // });
    
          // document.body.appendChild(requestButton);
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
