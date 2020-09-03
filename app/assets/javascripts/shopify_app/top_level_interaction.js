(function() {
  function setUpTopLevelInteraction() {
    var TopLevelInteraction = new ITPHelper({
      redirectUrl: document.body.dataset.redirectUrl,
    });

    TopLevelInteraction.execute();
  }

  document.addEventListener("DOMContentLoaded", setUpTopLevelInteraction);
})();
