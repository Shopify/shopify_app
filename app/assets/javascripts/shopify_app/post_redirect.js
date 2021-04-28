(function() {
  function redirect() {
    var form = document.getElementById("redirect-form");
    if (form) {
      form.submit();
    }
  }
  window.addEventListener("load", redirect);
})();
