function setCookieAndRedirect() {
  document.cookie = "shopify.cookies_persist=true";
  window.location.href = window.shopOrigin + "/admin/apps/" + window.apiKey;
}

document.addEventListener("DOMContentLoaded", function() {
  if (document.hasStorageAccess) {
    var itpContent = document.querySelector('#CookiePartitionPrompt');
    itpContent.style.display = 'block';

    var button = document.querySelector('#AcceptCookies');
    button.addEventListener('click', setCookieAndRedirect);
  } else {
    setCookieAndRedirect();
  }
});
