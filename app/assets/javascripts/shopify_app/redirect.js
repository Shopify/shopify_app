document.addEventListener("DOMContentLoaded", function() {
  var redirectTargetElement = document.getElementById("redirection-target");
  var targetInfo = JSON.parse(redirectTargetElement.dataset.target);

  var CAN_USE_COOKIES = 'can_use_cookies=true';

  function redirect() {
    document.cookie = CAN_USE_COOKIES;
    window.top.location.href = targetInfo.url;
  }

  if (window.top == window.self) {
    // If Storage Access API is available, generate UI for user to interact with to trigger cookie partitioning
    if (!document.hasStorageAccess) {
      redirect();
      return;
    }

    // Pre-partition: Prevents second redirect to button page (still does two redirects to app as TLD)
    // Post-partition: document.cookie doesn't persist; still redirects once to button page
    var allCookies = document.cookie;
    var shouldRedirect = allCookies.search(CAN_USE_COOKIES);

    if (shouldRedirect < 0) {
      const button = document.createElement('button');
      button.innerHTML = 'Request Storage Access';
      button.addEventListener('click', redirect);
      document.body.appendChild(button);
    } else {
      redirect();
    }

    // Buggy
    // Pre-partition: Causes infinite redirects (hasAccess is true?)
    // Post-partition: Prevents redirect to button page, but embedded app does not always load
    // document.hasStorageAccess().then((hasAccess) => {
    //   if (hasAccess) {
    //     redirect();
    //     return;
    //   }

    //   const button = document.createElement('button');
    //   button.innerHTML = 'Request Storage Access';
    //   button.addEventListener('click', redirect);
    //   document.body.appendChild(button);
    // });
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
