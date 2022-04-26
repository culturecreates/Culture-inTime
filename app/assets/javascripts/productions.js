
$(function() {
  $( ".propSpotlight" ).on( "click", function() {
    $( ".propAll" ).removeClass("active");
    $( ".propSpotlight" ).addClass("active");
  });
  $( ".propAll" ).on( "click", function() {
    $( ".propSpotlight" ).removeClass("active");
    $( ".propAll" ).addClass("active");
  });

  });
