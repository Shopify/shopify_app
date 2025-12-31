(function () {
  if (!window.fetch || !window.Promise) {
    return;
  }

  var config = window.BC_DEPOSIT_SYNC;

  if (!config || !config.depositHandle || !config.variantIdByValue) {
    return;
  }

  var depositHandle = config.depositHandle;
  var variantIdByValue = config.variantIdByValue;
  var isSyncing = false;
  var syncQueued = false;
  var originalFetch = window.fetch.bind(window);

  function normalizeDepositValue(value) {
    if (value === null || value === undefined) {
      return null;
    }

    var normalized = String(value).trim();
    return normalized.length ? normalized : null;
  }

  function parseContainersPerUnit(value) {
    var parsed = parseInt(value, 10);
    return isNaN(parsed) ? null : parsed;
  }

  function extractUrl(resource) {
    if (typeof resource === "string") {
      return resource;
    }

    if (resource && typeof resource.url === "string") {
      return resource.url;
    }

    return "";
  }

  function isCartMutation(resource) {
    var url = extractUrl(resource);
    if (!url) {
      return false;
    }

    try {
      url = new URL(url, window.location.origin).pathname;
    } catch (error) {
      return /\/cart\/(add|change|update)\.js/.test(url);
    }

    return /\/cart\/(add|change|update)\.js/.test(url);
  }

  function queueSync() {
    if (syncQueued) {
      return;
    }

    syncQueued = true;
    setTimeout(function () {
      syncQueued = false;
      syncDeposits();
    }, 0);
  }

  function fetchJson(path, options) {
    var fetchOptions = {
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
    };

    if (options) {
      Object.keys(options).forEach(function (key) {
        fetchOptions[key] = options[key];
      });
    }

    return originalFetch(path, fetchOptions).then(function (response) {
      return response.json();
    });
  }

  function fetchCart() {
    return fetchJson("/cart.js");
  }

  function changeLineItem(key, quantity) {
    return fetchJson("/cart/change.js", {
      method: "POST",
      body: JSON.stringify({
        id: key,
        quantity: quantity,
      }),
    });
  }

  function addVariant(variantId, quantity) {
    return fetchJson("/cart/add.js", {
      method: "POST",
      body: JSON.stringify({
        id: variantId,
        quantity: quantity,
      }),
    });
  }

  function buildRequiredDeposits(items) {
    return items.reduce(function (required, item) {
      if (item.handle === depositHandle) {
        return required;
      }

      var properties = item.properties || {};
      var depositValue = normalizeDepositValue(properties._deposit);
      var containersPerUnit = parseContainersPerUnit(properties._containers_per_unit);

      if (!depositValue || !containersPerUnit || containersPerUnit <= 0) {
        return required;
      }

      var variantId = variantIdByValue[depositValue];
      if (!variantId) {
        return required;
      }

      var total = item.quantity * containersPerUnit;
      required[variantId] = (required[variantId] || 0) + total;
      return required;
    }, {});
  }

  function buildDepositUpdates(items, requiredByVariantId) {
    var updates = [];

    items.forEach(function (item) {
      if (item.handle !== depositHandle) {
        return;
      }

      var desiredQuantity = requiredByVariantId[item.variant_id] || 0;

      if (item.quantity !== desiredQuantity) {
        updates.push({
          key: item.key,
          quantity: desiredQuantity,
        });
      }

      delete requiredByVariantId[item.variant_id];
    });

    return updates;
  }

  function buildDepositAdds(requiredByVariantId) {
    return Object.keys(requiredByVariantId)
      .map(function (variantId) {
        return {
          id: variantId,
          quantity: requiredByVariantId[variantId],
        };
      })
      .filter(function (entry) {
        return entry.quantity > 0;
      });
  }

  function applyUpdates(updates, adds) {
    var sequence = Promise.resolve();

    updates.forEach(function (update) {
      sequence = sequence.then(function () {
        return changeLineItem(update.key, update.quantity);
      });
    });

    adds.forEach(function (entry) {
      sequence = sequence.then(function () {
        return addVariant(entry.id, entry.quantity);
      });
    });

    return sequence;
  }

  function syncDeposits() {
    if (isSyncing) {
      return Promise.resolve();
    }

    isSyncing = true;

    return fetchCart()
      .then(function (cart) {
        var items = (cart && cart.items) || [];
        var requiredByVariantId = buildRequiredDeposits(items);
        var updates = buildDepositUpdates(items, requiredByVariantId);
        var adds = buildDepositAdds(requiredByVariantId);

        if (!updates.length && !adds.length) {
          return null;
        }

        return applyUpdates(updates, adds);
      })
      .catch(function () {})
      .then(function () {
        isSyncing = false;
      });
  }

  window.fetch = function () {
    var args = arguments;
    return originalFetch.apply(window, args).then(function (response) {
      if (!isSyncing && isCartMutation(args[0])) {
        queueSync();
      }

      return response;
    });
  };

  document.addEventListener("DOMContentLoaded", queueSync);
  queueSync();
})();
