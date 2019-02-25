var eventName = typeof(Turbolinks) !== 'undefined' ? 'turbolinks:load' : 'DOMContentLoaded';

if (!document.documentElement.hasAttribute("data-turbolinks-preview")) {
  document.addEventListener(eventName, function flash() {
    var flash = JSON.parse(document.getElementById('flash').dataset.flash);

    if (flash.notice) {
      ShopifyApp.flashNotice(flash.notice);
    }

    if (flash.error) {
      ShopifyApp.flashError(flash.error);
    }

    document.removeEventListener(eventName, flash)
  });
}
