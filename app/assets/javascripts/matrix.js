var localStorage = window.localStorage;
// the filter to pass to the homeserver
// matrix docs recommend creating a filter using the filter API for these situations; might want to do that
var filter = '{"event_fields":[],"account_data":{"types":[]},"presence":{"types":[]},' + 
    '"room":{"account_data":{"types":[]},"timeline":{"limit":1},"ephemeral":{"types":[]},"state":{"types":[]}}}';

// a function to update the unread messages displayed by the mail icon
function updateUnreadCounter(counter, oldval){
  // find the counter elements if they are not passed as an argument
  counter = typeof(counter) !== "undefined" ? counter : $(".unread-messages-counter");
  oldval = typeof(oldval) !== "undefined" ? oldval : 0; // default old value is assumed to be 0
  var url = localStorage.getItem("mx_hs_url"); // homeserver address
  var token = localStorage.getItem("mx_access_token"); // user's access token

  // if the necessary ingredients are lacking, give it a few seconds and try again
  if (counter.length === 0 || url == null || token == null) {
    setTimeout(updateUnreadCounter, 5000);
    return;
  }

  // get /_matrix/client/r0/sync from the homeserver, then count all unread notifications and update the page
  $.getJSON(url + "/_matrix/client/r0/sync?access_token=" + token + "&filter=" + filter, function(result, status) {
    if (status === "success") { // if the request succeeded
      var counterVal = 0; // notification count
      $.each(result.rooms.join, function(name, room) { // for each room the user has joined
        counterVal += room.unread_notifications.notification_count; // add to the count
      });

      if (oldval !== counterVal) { // update page if necessary
        counter.text(counterVal.toString()); // update counter to reflect new value
        if (counterVal === 0) {
          counter.addClass("hidden"); // hide counter if no messages
        } else {
          counter.removeClass("hidden"); // show counter otherwise
        }
      }
    }

    // wait the specified number of milliseconds, then refresh the counter
    setTimeout(function() { updateUnreadCounter(counter, counterVal); }, 1000);
  });
}

$(document).ready(function() {
  if (app.currentUser.authenticated()) {
    if (localStorage.getItem("mx_access_token") == undefined) {
      $.post('api/v1/matrix', function (data) {
        if (data['user_id'] && data['access_token'] && data['home_server']) {
          localStorage.setItem("mx_user_id", data['user_id']);
          localStorage.setItem("mx_access_token", data['access_token']);
          if (gon.appConfig.server.rails_environment == "development") {
            localStorage.setItem("mx_hs_url", gon.appConfig.matrix.listener_url);
          } else {
            localStorage.setItem("mx_hs_url", "https://" + data['home_server']);
          }
        } else {
          console.error('No matrix access token found!');
        }
      });
    }

    // set updateUnreadCounter to execute when the document is ready
    // the wrapper function is to ignore the argument jQuery tries to pass
    $(function(){updateUnreadCounter();});
  } else {
    localStorage.removeItem("mx_user_id");
    localStorage.removeItem("mx_access_token");
    localStorage.removeItem("mx_hs_url");
  }
})
