// Ensure template dropdown always has at least one option
document.addEventListener('DOMContentLoaded', function() {
  const templateSelect = document.getElementById('template');
  if (templateSelect) {
    // If the select has no options, add a default one
    if (templateSelect.options.length === 0) {
      const defaultOption = document.createElement('option');
      defaultOption.value = 'standard';
      defaultOption.text = 'Standard';
      templateSelect.add(defaultOption);
      
      console.log('Added default template option because no options were found');
    }
    
    // Log the available options for debugging
    console.log('Template options:');
    Array.from(templateSelect.options).forEach(function(option) {
      console.log(' - ' + option.value + ': ' + option.text);
    });
  }
}); 