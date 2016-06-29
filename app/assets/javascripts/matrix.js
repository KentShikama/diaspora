"use strict";
require("matrix-js-sdk");

var client = matrixcs.createClient("http://matrix.org");
client.publicRooms(function (err, data) {
  if (err) {
    console.error("err %s", JSON.stringify(err));
    return;
  }
  console.log("data %s [...]", JSON.stringify(data).substring(0, 1000));
  console.log("Congratulations! The SDK is working on the browser!");
});
