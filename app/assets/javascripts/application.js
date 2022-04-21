// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require activestorage

// Loads all Semantic javascripts
//= require semantic-ui

//= require_tree .


$(function() {
  $('.ui.accordion')
    .accordion()
  ;

  MemberStack.onReady.then(function(member) {   
    // check if member is logged in   
    if (member.loggedIn)  {
      Cookies.set('user', member["email"])
    } else {
      Cookies.remove('user')
    }  });

  // Load Productions button should indicate loading
  $('.show_loading').on("click",function() {
    $(this).addClass("loading");
  });

  $('.show_loading_if_confirmed').on('confirm:complete', function(e, response) {
    if(response) {
      // User confirmed
      $(this).addClass("loading");
    }
    else {
      // User cancelled. Do nothing.
    }
  });

});