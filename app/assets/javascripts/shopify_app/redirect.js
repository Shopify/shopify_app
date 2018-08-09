document.addEventListener("DOMContentLoaded", function() {
  var redirectTargetElement = document.getElementById("redirection-target");
  var targetInfo = JSON.parse(redirectTargetElement.dataset.target);

  function redirect() {
    document.cookie = 'can_use_cookies=true';
    window.top.location.href = targetInfo.url;
  }

  if (window.top == window.self) {
    // If Storage Access API is available, generate UI for user to interact with to trigger cookie partitioning
    if (!document.hasStorageAccess) {
      redirect();
      return;
    }

    // Prevents second redirect pre-partition
    // if (!document.cookie) {
    //   const button = document.createElement('button');
    //   button.innerHTML = 'Request Storage Access';
    //   button.addEventListener('click', redirect);
    //   document.body.appendChild(button);
    // } else {
    //   redirect();
    // }

    // Prevents button view post-partition
    // Causes infinite loop pre-partition (hasAccess is true?)
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
