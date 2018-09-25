function redirectToAppTLD(opts) {
  // needed for first redirect, if merchant has not interacted with TLD
  var normalizedLink = document.createElement('a');

  normalizedLink.href = opts.hasStorageAccess ? opts.redirectInfo.hasStorageAccessUrl : opts.redirectInfo.doesNotHaveStorageAccessUrl;

  data = JSON.stringify({
    message: 'Shopify.API.remoteRedirect',
    data: {
      location: normalizedLink.href,
    }
  });
  window.parent.postMessage(data, opts.redirectInfo.myshopifyUrl);
  sessionStorage.setItem('shopify.has_redirected', 'true');
}

function redirectToAppHome(homeURL) {
  sessionStorage.setItem('shopify.granted_storage_access', 'true');
  window.location.href = `${homeURL}`;
}

function renderRequestStorageAccess(redirectInfo) {
  const requestContent = document.querySelector('#RequestStorageAccess');
  const requestButton = document.querySelector('#TriggerAllowCookiesPrompt');

  var onStorageAccessGranted = redirectToAppHome.bind(null, redirectInfo.home);
  var onStorageAccessDenied = redirectToAppTLD.bind(null, {hasStorageAccess: false, redirectInfo: redirectInfo});

  requestButton.addEventListener('click', () => {
    // If request for storage access is rejected, change the parent's URL with postMessage.
    // If storage access is granted, redirect child to app home page
    document.requestStorageAccess().then(onStorageAccessGranted, onStorageAccessDenied);
  });
  requestContent.style.display = 'block';
}

function handleStorageAccess(redirectInfo) {
  document.hasStorageAccess().then((hasAccess) => {
    if (hasAccess) {
      if (sessionStorage.getItem('shopify.granted_storage_access')) {
        // If app was classified by ITP and used Storage Access API to acquire access
        redirectToAppHome(redirectInfo.home);
      } else {
        // If app has not been classified by ITP and still has storage access
        redirectToAppTLD({hasStorageAccess: true, redirectInfo: redirectInfo});
      }
    } else {
      if (sessionStorage.getItem('shopify.has_redirected')) {
        // If merchant has been redirected to interact with TLD (requirement for prompting request to gain storage access)
        renderRequestStorageAccess(redirectInfo);
      } else {
        // If merchant has not been redirected to interact with TLD (requirement for prompting request to gain storage access)
        redirectToAppTLD({hasStorageAccess: false, redirectInfo: redirectInfo});
      }
    }
  });
}