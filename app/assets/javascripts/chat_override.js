var ga = null; // Workaround to say no Google Analytics
Velocity = $.Velocity; // Workaround for adding javascript
$(document).ready(function () {
  $(window).trigger('resize');
});
$(window).resize(function() {
  $('#matrixchat').height($(window).height() - 50); // 50px for the header offset
});
