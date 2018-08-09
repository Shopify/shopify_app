document.addEventListener("DOMContentLoaded", function() {
  var redirectTargetElement = document.getElementById("redirection-target");
  var targetInfo = JSON.parse(redirectTargetElement.dataset.target);

  function redirect() {
    window.top.location.href = targetInfo.url;
  }

  if (window.top == window.self) {
    if (!shouldTriggerCookiePartitioning()) {
      redirect();
      return;
    }

    var button = document.createElement('button');
    button.innerHTML = 'Allow third-party cookies';
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
