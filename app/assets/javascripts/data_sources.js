
$(function() {
  if($("#job_count").length){
    setInterval(function()
      {
        $.ajax("/queue/check_jobs");
      }, 5000); //5000 is 5 sec in ms
  }
});