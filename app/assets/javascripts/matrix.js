var localStorage = window.localStorage;
// the filter to pass to the homeserver
// potential TODO: matrix docs recommend creating a filter using the filter API for these situations
// although the reason given is that sending the filter every time is too much overhead and ours is pretty short
var filter = '{"event_fields":[],"account_data":{"types":[]},"presence":{"types":[]},' +
    '"room":{"account_data":{"types":[]},"timeline":{"types":[]},"ephemeral":{"types":[]},"state":{"types":[]}}}';
var timeout = 30000; // amount of time the server will wait for an event before returning, in milliseconds
// a function to update the unread messages displayed by the mail icon
// takes the html elements to be updated and a token telling the server when the last update was as arguments
function updateUnreadCounter(counter, since_token) {
// find the counter elements if they are not passed as an argument
  counter = counter != undefined ? counter : $(".unread-messages-counter");
// if the since token exists, make the corresponding URL parameter
  var since_param = since_token != undefined ? "&since=" + since_token : "&full_state=true";
  var url = localStorage.getItem("mx_hs_url"); // homeserver address
  var token = localStorage.getItem("mx_access_token"); // user's access token

// if the necessary ingredients are lacking, give it a few seconds and try again
  if (counter.length === 0 || url == null || token == null) {
    setTimeout(updateUnreadCounter, 5000);
    return;
  }

// get /_matrix/client/r0/sync from the homeserver, then count all unread notifications and update the page
  $.getJSON(url + "/_matrix/client/r0/sync?access_token=" + token + "&filter=" + filter + "&timeout=" + timeout +
      since_param, function(result, status) {
    if (status === "success") {
      if (!_.isEmpty(result.rooms.join)) {
        var counterVal = 0; // notification count
        $.each(result.rooms.join, function(name, room) { // for each room the user has joined
          if (room.unread_notifications.notification_count != undefined) { // which has a notification count
            counterVal += room.unread_notifications.notification_count; // add to the total count
          }
        });

        counter.text(counterVal.toString()); // update counter to reflect new value
        if (counterVal === 0) {
          counter.addClass("hidden"); // hide counter if no messages
        } else {
          counter.removeClass("hidden"); // show counter otherwise
        }
      }
    }

    // immediately poll the server again
    updateUnreadCounter(counter, result.next_batch);
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
    $(function() { updateUnreadCounter(); });
  } else {
    localStorage.removeItem("mx_user_id");
    localStorage.removeItem("mx_access_token");
    localStorage.removeItem("mx_hs_url");
  }
})
