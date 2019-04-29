(function() {
  function redirect() {
    var redirectTargetElement = document.getElementById("redirection-target");

    var targetInfo = JSON.parse(redirectTargetElement.dataset.target)

    if (window.top == window.self) {
      // If the current window is the 'parent', change the URL by setting location.href
      window.top.location.href = targetInfo.hasStorageAccessUrl;
    } else {
        var storageAccessHelper = new StorageAccessHelper(targetInfo);
        storageAccessHelper.execute();
    }
  }

  document.addEventListener("DOMContentLoaded", redirect);
})();
