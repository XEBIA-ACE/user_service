"use strict";

(function () {
  var SCHEMA_URL = "/api/v1/users/register";
  var EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  var FIELD_ORDER = ["full_name", "email_address", "password", "consent_accepted"];
  var FIELD_LABELS = {
    full_name: "Full name",
    email_address: "Email address",
    password: "Password",
    consent_accepted: "Terms of Service and Privacy Policy"
  };

  var passwordPolicy = {
    min_length: 8,
    max_length: 128,
    rules: [
      { id: "lowercase", pattern: "[a-z]", message: "must include a lowercase letter" },
      { id: "uppercase", pattern: "[A-Z]", message: "must include an uppercase letter" },
      { id: "digit", pattern: "[0-9]", message: "must include a digit" },
      { id: "special", pattern: "[\\W_]", message: "must include a special character" }
    ]
  };

  var form = document.getElementById("registration-form");
  var submitButton = document.getElementById("submit-button");
  var summary = document.getElementById("error-summary");
  var summaryList = document.getElementById("error-summary-list");
  var statusRegion = document.getElementById("status");

  function field(name) { return document.getElementById(name); }

  function loadPolicy() {
    return fetch(SCHEMA_URL, { headers: { Accept: "application/json" }, credentials: "same-origin" })
      .then(function (res) { return res.ok ? res.json() : null; })
      .then(function (schema) {
        if (schema && schema.password_policy) { passwordPolicy = schema.password_policy; }
      })
      .catch(function () { /* fall back to the built-in policy; server validates regardless */ });
  }

  function passwordViolations(value) {
    var messages = [];
    if (value.length < passwordPolicy.min_length) {
      messages.push("must be at least " + passwordPolicy.min_length + " characters");
    }
    if (value.length > passwordPolicy.max_length) {
      messages.push("must be at most " + passwordPolicy.max_length + " characters");
    }
    passwordPolicy.rules.forEach(function (rule) {
      if (!new RegExp(rule.pattern).test(value)) { messages.push(rule.message); }
    });
    return messages;
  }

  function updatePasswordRules() {
    var value = field("password").value;
    var lengthOk = value.length >= passwordPolicy.min_length && value.length <= passwordPolicy.max_length;
    document.querySelectorAll("#password-rules li").forEach(function (item) {
      var id = item.getAttribute("data-rule");
      var met = id === "length" ? lengthOk : passwordPolicy.rules.some(function (rule) {
        return rule.id === id && new RegExp(rule.pattern).test(value);
      });
      item.classList.toggle("met", met);
    });
  }

  function validateField(name) {
    var input = field(name);
    var value = input.type === "checkbox" ? input.checked : input.value.trim();

    switch (name) {
      case "full_name":
        return value ? [] : ["Enter your full name"];
      case "email_address":
        if (!value) { return ["Enter your email address"]; }
        return EMAIL_PATTERN.test(value) ? [] : ["Enter an email address in the correct format, like name@example.com"];
      case "password":
        if (!input.value) { return ["Enter a password"]; }
        return passwordViolations(input.value).map(function (m) { return "Password " + m; });
      case "consent_accepted":
        return value ? [] : ["You must agree to the Terms of Service and Privacy Policy"];
      default:
        return [];
    }
  }

  function showFieldError(name, messages) {
    var input = field(name);
    var error = document.getElementById(name + "-error");
    var wrapper = document.getElementById(name + "-field");

    if (messages.length) {
      error.textContent = messages.join(". ");
      error.hidden = false;
      input.setAttribute("aria-invalid", "true");
      wrapper.classList.add("has-error");
    } else {
      error.textContent = "";
      error.hidden = true;
      input.removeAttribute("aria-invalid");
      wrapper.classList.remove("has-error");
    }
  }

  function showSummary(errorsByField) {
    summaryList.innerHTML = "";
    FIELD_ORDER.forEach(function (name) {
      (errorsByField[name] || []).forEach(function (message) {
        var item = document.createElement("li");
        var link = document.createElement("a");
        link.href = "#" + name;
        link.textContent = message;
        link.addEventListener("click", function (event) {
          event.preventDefault();
          field(name).focus();
        });
        item.appendChild(link);
        summaryList.appendChild(item);
      });
    });
    (errorsByField.base || []).forEach(function (message) {
      var item = document.createElement("li");
      item.textContent = message;
      summaryList.appendChild(item);
    });
    summary.hidden = summaryList.children.length === 0;
    if (!summary.hidden) { summary.focus(); }
  }

  function clearSummary() {
    summary.hidden = true;
    summaryList.innerHTML = "";
  }

  function validateAll() {
    var errors = {};
    FIELD_ORDER.forEach(function (name) {
      var messages = validateField(name);
      showFieldError(name, messages);
      if (messages.length) { errors[name] = messages; }
    });
    return errors;
  }

  function serverErrors(details) {
    var errors = {};
    Object.keys(details || {}).forEach(function (key) {
      var label = FIELD_LABELS[key];
      errors[key] = [].concat(details[key]).map(function (message) {
        return label ? label + " " + message : message;
      });
    });
    return errors;
  }

  function showConfirmation(body) {
    document.getElementById("registration").hidden = true;
    var confirmation = document.getElementById("confirmation");
    document.getElementById("confirmation-message").textContent = body.message;
    confirmation.hidden = false;
    document.getElementById("confirmation-heading").focus();

    // Demonstrates authenticated access using the HttpOnly session cookie.
    fetch("/api/v1/users/me", { headers: { Accept: "application/json" }, credentials: "same-origin" })
      .then(function (res) { return res.ok ? res.json() : null; })
      .then(function (me) {
        if (!me || !me.data) { return; }
        var signedInAs = document.getElementById("signed-in-as");
        signedInAs.textContent = "Signed in as " + me.data.attributes.email + ".";
        signedInAs.hidden = false;
      })
      .catch(function () {});
  }

  function submit(event) {
    event.preventDefault();
    clearSummary();

    var errors = validateAll();
    if (Object.keys(errors).length) {
      showSummary(errors);
      return;
    }

    submitButton.disabled = true;
    statusRegion.textContent = "Creating your account…";

    fetch(form.action, {
      method: "POST",
      credentials: "same-origin",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify({
        full_name: field("full_name").value.trim(),
        email_address: field("email_address").value.trim(),
        password: field("password").value,
        consent_accepted: field("consent_accepted").checked
      })
    })
      .then(function (res) {
        return res.json().catch(function () { return {}; }).then(function (body) {
          return { status: res.status, body: body };
        });
      })
      .then(function (result) {
        if (result.status === 201) {
          statusRegion.textContent = "";
          showConfirmation(result.body);
          return;
        }
        var details = (result.body.error && result.body.error.details) || {};
        var mapped = serverErrors(details);
        FIELD_ORDER.forEach(function (name) { showFieldError(name, mapped[name] || []); });
        if (!Object.keys(mapped).length) {
          mapped.base = ["Something went wrong. Please try again."];
        }
        statusRegion.textContent = "";
        showSummary(mapped);
      })
      .catch(function () {
        statusRegion.textContent = "";
        showSummary({ base: ["We could not reach the server. Check your connection and try again."] });
      })
      .finally(function () { submitButton.disabled = false; });
  }

  FIELD_ORDER.forEach(function (name) {
    var input = field(name);
    var eventName = input.type === "checkbox" ? "change" : "blur";
    input.addEventListener(eventName, function () { showFieldError(name, validateField(name)); });
  });
  field("password").addEventListener("input", updatePasswordRules);
  form.addEventListener("submit", submit);

  loadPolicy().then(updatePasswordRules);
})();
