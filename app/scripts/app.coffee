"use strict"

window.app = angular.module("TubePlates", [
  "angular-table"
  "ngResource"
  "ui.sortable"
  "youtube"
])

app.run([
   '$location'
   ($location) ->
    if $location.absUrl().indexOf("https://") != -1
        alert("Using HTTPS on this site can cause unexpected behaviour"\
            + " because Discogs doesn't support HTTPS fully")

])
