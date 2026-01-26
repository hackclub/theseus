import LetterAttributesPicker from '../components/LetterAttributesPicker.svelte';
import MailScanner from '../components/MailScanner.svelte';

const components = {
  'letter-attributes-picker': LetterAttributesPicker,
  'mail-scanner': MailScanner,
};

export function mountSvelteComponents() {
  document.querySelectorAll('[data-svelte-component]').forEach((target) => {
    const componentName = target.dataset.svelteComponent;
    const Component = components[componentName];

    if (!Component) {
      console.warn(`Unknown Svelte component: ${componentName}`);
      return;
    }

    // Parse props from data attributes
    const props = {};
    Object.keys(target.dataset).forEach((key) => {
      if (key === 'svelteComponent') return;

      let value = target.dataset[key];

      // Try to parse as JSON for complex values
      try {
        value = JSON.parse(value);
      } catch (e) {
        // Keep as string if not valid JSON
      }

      // Convert kebab-case data attributes to camelCase props
      props[key] = value;
    });

    // Mount the component
    new Component({
      target,
      props,
    });
  });
}

// Auto-mount on DOMContentLoaded and Turbo navigation
if (typeof document !== 'undefined') {
  document.addEventListener('DOMContentLoaded', mountSvelteComponents);
  document.addEventListener('turbo:load', mountSvelteComponents);
  document.addEventListener('turbo:render', mountSvelteComponents);
}
