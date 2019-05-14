var eventName = typeof(Turbolinks) !== 'undefined' ? 'turbolinks:load' : 'DOMContentLoaded';

if (!document.documentElement.hasAttribute("data-turbolinks-preview")) {
  document.addEventListener(eventName, function flash() {
    var flashData = JSON.parse(document.getElementById('shopify-app-flash').dataset.flash);

    if (flashData.notice) {
      ShopifyApp.flashNotice(flashData.notice);
    }

    if (flashData.error) {
      ShopifyApp.flashError(flashData.error);
    }

    document.removeEventListener(eventName, flash)
  });
}
