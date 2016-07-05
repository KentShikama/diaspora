var localStorage = window.localStorage;

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
            localStorage.setItem("mx_hs_url", data['home_server']);
          }
        } else {
          console.error('No matrix access token found!');
        }
      });
    }
  } else {
    localStorage.removeItem("mx_user_id");
    localStorage.removeItem("mx_access_token");
    localStorage.removeItem("mx_hs_url");
  }
})
