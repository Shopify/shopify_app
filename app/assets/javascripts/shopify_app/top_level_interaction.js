(function() {
  function setUpTopLevelInteraction() {
    var TopLevelInteraction = new ITPHelper({
      content: '#TopLevelInteractionContent',
      action: '#TopLevelInteractionButton',
    });

    if (TopLevelInteraction.userAgentIsAffected() && navigator.userAgent.indexOf('Version/12.1 Safari') >= 0) {
      TopLevelInteraction.setUpContent();
    } else {
      TopLevelInteraction.redirectToEmbedded();
    }
  }

  document.addEventListener("DOMContentLoaded", setUpTopLevelInteraction);
})();
