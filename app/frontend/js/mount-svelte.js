import { mount } from 'svelte';
import LetterAttributesPicker from '../components/LetterAttributesPicker.svelte';
import MailScanner from '../components/MailScanner.svelte';
import BatchCsvMapper from '../components/BatchCsvMapper.svelte';
import CommandPalette from '../components/CommandPalette.svelte';

const components = {
  'letter-attributes-picker': LetterAttributesPicker,
  'mail-scanner': MailScanner,
  'batch-csv-mapper': BatchCsvMapper,
  'command-palette': CommandPalette,
};

export function mountSvelteComponents() {
  document.querySelectorAll('[data-svelte-component]').forEach((target) => {
    const componentName = target.dataset.svelteComponent;
    const Component = components[componentName];

    if (!Component) {
      console.warn(`Unknown Svelte component: ${componentName}`);
      return;
    }

    const props = {};
    Object.keys(target.dataset).forEach((key) => {
      if (key === 'svelteComponent') return;

      let value = target.dataset[key];
      try {
        value = JSON.parse(value);
      } catch (e) {}

      props[key] = value;
    });

    mount(Component, { target, props });
  });
}

// Auto-mount on DOMContentLoaded and Turbo navigation
if (typeof document !== 'undefined') {
  document.addEventListener('DOMContentLoaded', mountSvelteComponents);
  document.addEventListener('turbo:load', mountSvelteComponents);
  document.addEventListener('turbo:render', mountSvelteComponents);
}
