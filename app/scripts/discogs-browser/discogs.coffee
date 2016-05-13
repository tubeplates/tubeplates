"use strict"

###
A service for fetching data using Discogs and the Discogs API
It also manipulates the data for easier usage in the app
###
app.factory "$discogs", [
  "$resource"
  "$q"
  "$discogsconfig"
  "$dcscraper"
  ($resource, $q, $cfg, $dcscraper) ->

    thumbfix = (item) ->
        item.thumb = item.thumb.replace("api.discogs",
                                        "s.pixogs")
                                .replace("images",
                                         "image")

    #Remove duplicate releases(same catno)
    remove_duplicates = (releases) ->
      catnos = {}
      ids = {}
      release_set = []
      for i,release of releases
        if (not catnos[release.catno] or not release.catno)\
           and not ids[release.id]
          release_set.push release
          catnos[release.catno] = true
          ids[release.id] = true
      release_set

    #Move all keys from resource.data to resource
    jsonp_keyfix = (resource) ->
      resource.$promise.then ->
        resource[k] = v for k,v of resource.data
        delete resource.data
      resource

    #Simple wrapper for discogs API
    DiscogsResource = (path) ->
      $resource $cfg.API_URL + path,{'callback':'JSON_CALLBACK'},
                                {get: {cache:true,method:'JSONP'}}

    #Get multiple pages of data using Discogs API
    MultiPageData = (path, listname, params, max_requests) ->
      params = params or {}
      params.per_page = params.per_page or 100
      max_requests = max_requests or 2
      requests = 0
      deferred = $q.defer()
      call = jsonp_keyfix( DiscogsResource(path).get(params) )
      first = call
      fetched = []

      nextPage = (promise) ->
        done = ->
          first[listname] = fetched
          deferred.resolve first
        promise = promise or call.$promise
        promise.then ->
          requests++
          fetched = fetched.concat(call[listname])
          nexturl = call.pagination.urls.next
          nextpage = call.pagination.page+1
          if nexturl and requests < max_requests
            params.page = nextpage
            call = jsonp_keyfix( DiscogsResource(path).get(params) )
            nextPage()
          else
            done()
        promise.catch -> done()

      nextPage()
      first.$promise = deferred.promise
      first

    #Release/Master
    Record = (params, path) ->
      deferred = $q.defer()
      release = jsonp_keyfix( DiscogsResource(path).get params )
      release.$promise.then ->
        re = new RegExp("[(][0-9]+[)]")
        tracks = []
        for trackindex,track of release.tracklist
          continue if not track.position or not track.title
          if track.artists
              artists = track.artists
          else if release.artists
              artists = release.artists
          track.artists = artists
          track.position = {display: track.position,\
                            sort: parseInt(trackindex)}
          tracks.push track
        release.tracklist = tracks
        deferred.resolve release
      release.$promise = deferred.promise
      release

    Artist = (params) ->
      jsonp_keyfix( DiscogsResource("/artists/:id").get params )

    ArtistReleasesAPI = (params,max_pages) ->
      deferred = $q.defer()
      artist = MultiPageData "/artists/:id/releases",\
                               "releases", params, max_pages or 6
      artist.$promise.then ->
        for index,release of artist.releases
          release.is_master = release.type == "master"
          release.type = "release"
          thumbfix(release)
        artist.releases = remove_duplicates(artist.releases)
        Artist({id:params.id}).$promise.then (artist_details) ->
          for key,value of artist_details
            artist[key] = value
          deferred.resolve artist
      artist.$promise = deferred.promise
      artist

    ScrapeArtistReleases = (params) ->
      deferred = $q.defer()
      resource = {'$promise':deferred.promise,'$resolved':false}
      $dcscraper.Artist(params.id).then (artist) ->
        resource[k] = v for k,v of artist
        resource.$resolved = true
        deferred.resolve resource
      resource

    #PUBLIC METHODS:

    Search: (params) ->
      return {'$promise': $dcscraper.Search(params) }

    Release: (params) ->
      Record(params,"/releases/:id")

    Master: (params) ->
      Record(params,"/masters/:id")

    Artist: Artist

    ArtistReleases: (params) ->
      MAX_PAGES = 6
      deferred = $q.defer()
      resource = {'$promise':deferred.promise,'$resolved':false}
      DiscogsResource("/artists/:id/releases")\
      .get({id: params.id,per_page: 1}).$promise.then (data) ->
        if data.data.pagination.items > MAX_PAGES*100
          ScrapeArtistReleases(params).$promise.then (data) ->
            resource[k] = v for k,v of data
            deferred.resolve resource
        else
          ArtistReleasesAPI(params,MAX_PAGES).$promise.then (data) ->
            resource[k] = v for k,v of data
            deferred.resolve resource
      resource

    Label: (params) ->
      jsonp_keyfix( DiscogsResource("/labels/:id").get params )

    LabelReleases: (params) ->
      deferred = $q.defer()
      resource = {'$promise':deferred.promise,'$resolved':false}
      $dcscraper.Label(params.id).then (label) ->
        for k,v of label
            resource[k] = v
        resource.$resolved = true
        deferred.resolve resource
      resource
]
