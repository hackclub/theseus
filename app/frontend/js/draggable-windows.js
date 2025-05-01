import $ from "jquery";

let cumulativeHeight = 0;
let currentZIndex = 1000;
const WINDOW_GAP = 10; // pixels between windows

$('.window').each(function(index) {
    const $window = $(this);
    const $titleBar = $window.find('.title-bar');
    let isDragging = false;
    let startX, startY, initialLeft, initialTop;

    // Set initial position for each window
    const windowHeight = $window.outerHeight();
    console.log(`Window ${index} height:`, windowHeight);
    
    // Offset by cumulative height of all previous windows plus gap
    const top = 50 + cumulativeHeight + (index * WINDOW_GAP);
    
    $window.css({
        position: 'absolute',
        left: '50px',
        top: `${top}px`,
        'z-index': currentZIndex + index
    });

    // Update cumulative height for next window
    cumulativeHeight += windowHeight;

    function bringToFront() {
        // Lower all other windows
        $('.window').not($window).each(function() {
            const currentZ = parseInt($(this).css('z-index'));
            if (currentZ > currentZIndex) {
                $(this).css('z-index', currentZ - 1);
            }
        });
        
        // Bring this window to front
        $window.css('z-index', currentZIndex + $('.window').length);
    }

    function startDrag(e) {
        bringToFront();
        console.log("startDrag");
        isDragging = true;
        startX = e.clientX;
        startY = e.clientY;
        initialLeft = $window.offset().left;
        initialTop = $window.offset().top;
        
        $(document).on('mousemove', drag);
        $(document).on('mouseup', stopDrag);
    }

    function drag(e) {
        if (!isDragging) return;
        
        const deltaX = e.clientX - startX;
        const deltaY = e.clientY - startY;
        
        $window.css({
            left: initialLeft + deltaX,
            top: initialTop + deltaY
        });
    }

    function stopDrag() {
        isDragging = false;
        $(document).off('mousemove', drag);
        $(document).off('mouseup', stopDrag);
    }

    $titleBar.on('mousedown', startDrag);
    $window.on('mousedown', bringToFront);
});