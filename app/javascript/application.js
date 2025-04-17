import "./controllers"
import "jquery"
import "@nathanvda/cocoon";
import "select2"

import "@selectize/selectize";

// $(document).ready (()=> {
//     $( ".needs-select2" ).select2()
//     document.addEventListener('vanilla-nested:fields-added', (e)=>{
//         $(e.target).find('.needs-select2').select2();
//     });
// });

// (select_the_2)
// $(document).on('vanilla-nested:fields-added')(select_the_2)

// Add development border overlay in non-production environments
document.addEventListener('DOMContentLoaded', () => {
  if (document.body.classList.contains('not_prod')) {
    const devBorderOverlay = document.createElement('div');
    devBorderOverlay.className = 'dev-border-overlay';
    document.body.appendChild(devBorderOverlay);
  }
});
