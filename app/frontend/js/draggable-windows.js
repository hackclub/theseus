import $ from "jquery";
import { initialize } from "@open-iframe-resizer/core";
let cumulativeHeight = 0;
let currentZIndex = 1000;
const WINDOW_GAP = 32; // pixels between windows
let windowCount = 0; // Track number of open windows

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

function openIframeWindow(url, title) {
    const windowId = `window-${Date.now()}`;
    const $window = $(`
        <div class="window iframe-window" id="${windowId}" style="width: fit-content; height: fit-content;">
            <div class="title-bar">
                <div class="title-bar-text">${title}</div>
                <div class="title-bar-controls">
                    <button aria-label="Maximize" onclick="window.location.href='${url}'"></button>
                    <button aria-label="Close" onclick="closeWindow('${windowId}')"></button>
                </div>
            </div>
            <div class="window-body" style="padding: 0;">
                <iframe src="${url}?framed=true" style="border: none;" id="${windowId}-frame"></iframe>
            </div>
        </div>
    `);

    // Get the last real window's position (exclude iframe windows)
    const $lastRealWindow = $('.window').not('.iframe-window').last();
    const lastWindowPosition = $lastRealWindow.length ? $lastRealWindow.offset() : { left: 50, top: 50 };

    // Position the new window with offset
    $window.css({
        position: 'absolute',
        left: `${lastWindowPosition.left + WINDOW_GAP}px`,
        top: `${lastWindowPosition.top + WINDOW_GAP}px`,
        'z-index': currentZIndex + $('.window').length
    });
    
    // Add to document and make draggable
    $('body').append($window);
    makeWindowDraggable($window);
    initialize({}, `#${windowId}-frame`);

    // Increment window count
    windowCount++;
}

function closeWindow(windowId) {
    const $window = $(`#${windowId}`);
    if ($window.length) {
        $window.remove();
        windowCount--;
    }
}

function makeWindowDraggable($window) {
    const $titleBar = $window.find('.title-bar');
    let isDragging = false;
    let startX, startY, initialLeft, initialTop;

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
}

// Make the functions available globally
window.openIframeWindow = openIframeWindow;
window.closeWindow = closeWindow;