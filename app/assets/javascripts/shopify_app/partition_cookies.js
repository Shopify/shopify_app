(function() {
  document.addEventListener("DOMContentLoaded", function() {
    var redirectTargetElement = document.getElementById("redirection-target");
    var targetInfo = JSON.parse(redirectTargetElement.dataset.target)
    var storageAccessHelper = new StorageAccessHelper(targetInfo);
    storageAccessHelper.execute();
  });
})();
