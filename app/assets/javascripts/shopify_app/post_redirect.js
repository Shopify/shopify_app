(function() {
  function redirect() {
    var form = document.getElementById("redirect-form");
    if (form) {
      form.submit();
    }
  }
  document.addEventListener("DOMContentLoaded", redirect);
})();
