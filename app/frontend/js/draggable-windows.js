import $ from "jquery";
import { initialize } from "@open-iframe-resizer/core";
let currentZIndex = 1000;
const WINDOW_GAP = 32; // pixels between windows
let windowCount = 0; // Track number of open windows

function findBestPosition(windowWidth, windowHeight) {
    // Positioning with carriage return
    const padding = 20;
    const windowGap = 20;
    const rowPadding = 20; // Padding between rows
    const zoom = 1.6; // Account for 160% zoom
    const effectiveWidth = window.innerWidth / zoom;
    
    let currentX = padding;
    let currentY = 90;
    let currentRowWindows = [];
    
    // Go through each existing positioned window to calculate position
    $('.window').each(function() {
        const $existing = $(this);
        const left = parseInt($existing.css('left'));
        
        // Only consider windows that have been positioned
        if (!isNaN(left) && left >= 0) {
            const existingWidth = $existing.outerWidth();
            const existingHeight = $existing.outerHeight();
            const existingId = $existing.attr('id');
            const nextX = currentX + existingWidth + windowGap;
            
            // Check if next window would go off screen OR if current window is backend-controls
            const shouldWrap = (nextX + windowWidth > effectiveWidth - padding) || 
                              (existingId === 'backend-controls');
            
            if (shouldWrap) {
                // Calculate height of current row based on tallest window
                const rowHeight = currentRowWindows.length > 0 ? 
                    Math.max(...currentRowWindows.map(w => w.height)) + rowPadding : 0;
                
                // Move to next row
                currentX = padding;
                currentY += rowHeight;
                currentRowWindows = []; // Reset for new row
            } else {
                currentX = nextX;
            }
            
            // Add this window to current row tracking
            currentRowWindows.push({ height: existingHeight });
        }
    });
    
    const position = {
        left: currentX,
        top: currentY
    };
    
    console.log('findBestPosition called:', { windowWidth, windowHeight, effectiveWidth, position });
    return position;
}

// Calculate positions for all initial windows first
const windowPositions = [];
const padding = 20;
const windowGap = 20;
const rowPadding = 20; // Padding between rows
const zoom = 1.6; // Account for 160% zoom

let currentX = padding;
let currentY = 90;
let currentRowWindows = []; // Track windows in current row

// Effective screen width accounting for zoom
const effectiveWidth = window.innerWidth / zoom;

console.log('Screen width:', window.innerWidth, 'Zoom:', zoom, 'Effective width:', effectiveWidth, 'Available width:', effectiveWidth - padding);

$('.window').each(function(index) {
    if (window.innerWidth <= 768) {
        return;
    }
    
    const $window = $(this);
    const windowWidth = $window.outerWidth();
    const windowHeight = $window.outerHeight();
    const windowId = $window.attr('id');
    
    console.log(`Window ${index}: id=${windowId}, width=${windowWidth}, height=${windowHeight}, currentX=${currentX}, wouldEndAt=${currentX + windowWidth}`);
    
    // Check if this window would go off screen (accounting for zoom) OR if previous window was backend-controls
    const shouldWrap = (index > 0 && currentX + windowWidth > effectiveWidth - padding) || 
                      (index > 0 && $('.window').eq(index - 1).attr('id') === 'backend-controls');
    
    if (shouldWrap) {
        const reason = $('.window').eq(index - 1).attr('id') === 'backend-controls' ? 'after backend-controls' : 'screen width';
        console.log(`Window ${index} WRAPPING (${reason})`);
        
        // Calculate height of current row based on tallest window
        const rowHeight = Math.max(...currentRowWindows.map(w => w.height)) + rowPadding;
        console.log(`Current row max height: ${rowHeight - rowPadding}px, moving to Y: ${currentY + rowHeight}`);
        
        // Move to next row
        currentX = padding;
        currentY += rowHeight;
        currentRowWindows = []; // Reset for new row
    } else {
        console.log(`Window ${index} fits on current row`);
    }
    
    // Add this window to current row tracking
    currentRowWindows.push({ height: windowHeight });
    
    // Store position for this window
    windowPositions[index] = {
        left: currentX,
        top: currentY
    };
    
    console.log('Calculated position for window', index, ':', windowPositions[index]);
    
    // Update currentX for next window
    currentX += windowWidth + windowGap;
});

// Now apply all the calculated positions
$('.window').each(function(index) {
    if (window.innerWidth <= 768) {
        return;
    }
    const $window = $(this);
    const $titleBar = $window.find('.title-bar');
    let isDragging = false;
    let startX, startY, initialLeft, initialTop;

    // Apply the pre-calculated position
    if (windowPositions[index]) {
        $window.css({
            position: 'absolute',
            left: `${windowPositions[index].left}px`,
            top: `${windowPositions[index].top}px`,
            'z-index': currentZIndex + index
        });
        
        console.log('Applied position to window', index, ':', windowPositions[index]);
    }

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
        initialLeft = parseInt($window.css('left'));
        initialTop = parseInt($window.css('top'));
        
        $(document).on('mousemove', drag);
        $(document).on('mouseup', stopDrag);
    }

    function drag(e) {
        if (!isDragging) return;
        
        const zoom = 1.6; // 160% zoom
        const deltaX = (e.clientX - startX) / zoom;
        const deltaY = (e.clientY - startY) / zoom;
        
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

    // Add to document first to get dimensions
    $('body').append($window);
    
    // Get window dimensions
    const windowWidth = $window.outerWidth();
    const windowHeight = $window.outerHeight();
    
    // Find best position
    const position = findBestPosition(windowWidth, windowHeight);
    
    // Position the window
    $window.css({
        position: 'absolute',
        left: `${position.left}px`,
        top: `${position.top}px`,
        'z-index': currentZIndex + $('.window').length
    });
    
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
    if (window.innerWidth <= 768) {
        return;
    }
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
        initialLeft = parseInt($window.css('left'));
        initialTop = parseInt($window.css('top'));
        
        $(document).on('mousemove', drag);
        $(document).on('mouseup', stopDrag);
    }

    function drag(e) {
        if (!isDragging) return;
        
        const zoom = 1.6; // 160% zoom
        const deltaX = (e.clientX - startX) / zoom;
        const deltaY = (e.clientY - startY) / zoom;
        
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