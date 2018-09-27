(function() {
  function setUpTopLevelInteraction() {
    var TopLevelInteraction = new ITPHelper({
      content: '#TopLevelInteractionContent',
      action: '#TopLevelInteractionButton',
    });

    if (!TopLevelInteraction.itpContent) {
      return;
    }

    if (TopLevelInteraction.userAgentIsAffected()) {
      TopLevelInteraction.setUpContent();
    } else {
      TopLevelInteraction.redirectToEmbedded();
    }
  }

  document.addEventListener("DOMContentLoaded", setUpTopLevelInteraction);
})();
