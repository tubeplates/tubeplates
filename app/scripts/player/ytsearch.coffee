"use strict"

###
A service for searching YouTube
###
app.factory "$ytsearch", [
  "$q"
  "$http"
  ($q, $http) ->

    Search = (query,params) ->
      deferred = $q.defer()
      getparams=
        orderby: "relevance"
        "max-results": 20
        "callback" : "JSON_CALLBACK"
        "key" : "AIzaSyBEMMeTl-Jt_LUL0D-gGzKb02deBUQ5AoM"
        "part" : "id,snippet"
        "type": "video"
        "videoEmbeddable" : "true"
        alt: "json"
        v: 3
      if params
        for k,v of params
          getparams[k] = v
      getparams['q'] = query
      first_call = $http(
            method: "JSONP"
            params: getparams
            cache: true
            url: "https://www.googleapis.com/youtube/v3/search"
        ).error (data, status, headers, config) ->
            console.log data
      first_call.then (data) ->
        ids = data.data.items.map (e) ->
            e.id.videoId
        ids_s = ids.join(",")
        getparams=
            "callback" : "JSON_CALLBACK"
            "key" : "AIzaSyBEMMeTl-Jt_LUL0D-gGzKb02deBUQ5AoM"
            "part" : "snippet,contentDetails"
            "id" : ids_s
            alt: "json"
            v: 3
        second_call = ($http(
                method: "JSONP"
                params: getparams
                cache: true
                url: "https://www.googleapis.com/youtube/v3/videos"
        ).error (data, status, headers, config) ->
            console.log data)
        second_call.then (data2) ->
            for i,item of data2.data.items
                data.data.items[i].duration = item.contentDetails.duration
                data.data.items[i].categoryID = item.snippet.categoryId
            deferred.resolve data
      deferred.promise

    Search : Search
]
