"use strict"

###
A service for searching YouTube
###
app.factory "$ytsearch", [
  "$q"
  "$http"
  ($q, $http) ->

    Search = (query,params) ->
      getparams=
        orderby: "relevance"
        "max-results": 20
        alt: "json"
        v: 2
      if params
        for k,v of params
          getparams[k] = v
      getparams['callback'] = "JSON_CALLBACK"
      getparams['q'] = query
      $http(
        method: "JSONP"
        params: getparams
        cache: true
        url: "https://gdata.youtube.com/feeds/api/videos"
      ).error (data, status, headers, config) ->
        console.log data

    Search : Search
]
