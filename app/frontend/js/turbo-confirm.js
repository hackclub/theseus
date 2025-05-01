import $ from "jquery";
$(document).ready(function() {
  $(document).on('submit', 'form[data-turbo-confirm]', function(e) {
    const message = $(this).data('turbo-confirm');
    if (!confirm(message)) {
      e.preventDefault();
    }
  });
}); 