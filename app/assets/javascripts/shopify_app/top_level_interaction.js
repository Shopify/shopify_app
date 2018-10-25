(function() {
  function setUpTopLevelInteraction() {
    var TopLevelInteraction = new ITPHelper({
      redirectUrl: window.redirectUrl,
    });

    TopLevelInteraction.execute();
  }

  document.addEventListener("DOMContentLoaded", setUpTopLevelInteraction);
})();
