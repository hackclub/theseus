const CONFIRM_ATTRIBUTES = ["data-turbo-confirm", "data-confirm"];
const CONFIRM_SELECTOR = "[data-turbo-confirm], [data-confirm]";
const CONFIRM_LINK_SELECTOR = "a[data-turbo-confirm], a[data-confirm]";

function messageFor(element) {
  if (!(element instanceof Element)) return null;
  for (const attribute of CONFIRM_ATTRIBUTES) {
    const value = element.getAttribute(attribute);
    if (value) return value;
  }
  return null;
}

function turboDriven(element) {
  const owner = element.closest("[data-turbo]");
  return owner ? owner.getAttribute("data-turbo") === "true" : false;
}

function decline(event) {
  event.preventDefault();
  event.stopImmediatePropagation();
}

document.addEventListener(
  "submit",
  (event) => {
    const form = event.target;
    if (!(form instanceof HTMLFormElement)) return;

    const submitter = event.submitter || form.querySelector(CONFIRM_SELECTOR);
    const message = messageFor(submitter) || messageFor(form);
    if (!message || turboDriven(form)) return;

    if (!window.confirm(message)) decline(event);
  },
  true
);

document.addEventListener(
  "click",
  (event) => {
    const target = event.target;
    if (!(target instanceof Element)) return;

    const link = target.closest(CONFIRM_LINK_SELECTOR);
    if (!link) return;

    const message = messageFor(link);
    if (!message || turboDriven(link)) return;

    if (!window.confirm(message)) decline(event);
  },
  true
);
