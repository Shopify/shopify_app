document.addEventListener("DOMContentLoaded", function() {
  var redirectTargetElement = document.getElementById("redirection-target");
  var targetInfo = JSON.parse(redirectTargetElement.dataset.target)

  if (window.top == window.self && canSetThirdPartyCookie()) {
    // If the current window is the 'parent', change the URL by setting location.href
    window.top.location.href = targetInfo.url;
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

function canSetThirdPartyCookie() {
  var cookie = "third_party_cookie_check=1"
  document.cookie = cookie
  return document.cookie.includes(cookie)
};
