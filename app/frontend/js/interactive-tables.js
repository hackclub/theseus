import $ from 'jquery';

$('table.interactive').each(function() {
    const $table = $(this);
    const highlightedClass = 'highlighted';
    
    $table.on('click', function(event) {
        const $target = $(event.target);
        const $newlySelectedRow = $target.closest('tr');
        const $previouslySelectedRow = $table.find('tr.' + highlightedClass);
        
        if ($previouslySelectedRow.length) {
            $previouslySelectedRow.removeClass(highlightedClass);
        }
        
        if ($newlySelectedRow.length) {
            $newlySelectedRow.toggleClass(highlightedClass);
        }
    });
});