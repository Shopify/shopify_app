(function() {
  function setUpTopLevelInteraction() {
    var TopLevelInteraction = new ITPHelper({
      content: '#TopLevelInteractionContent',
      action: '#TopLevelInteractionButton',
      redirectUrl: window.redirectUrl
    });

    if (!TopLevelInteraction.itpContent) {
      return;
    }

    if (TopLevelInteraction.userAgentIsAffected()) {
      TopLevelInteraction.setUpContent();
    } else {
      TopLevelInteraction.redirect();
    }
  }

  document.addEventListener("DOMContentLoaded", setUpTopLevelInteraction);
})();
