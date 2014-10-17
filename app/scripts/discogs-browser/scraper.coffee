"use strict"

###
A service for scraping Discogs
Should only be used when the API is missing features
###
app.factory "$dcscraper", [
  "$q"
  "$http"
  "$discogsconfig"
  ($q,$http,$cfg) ->
    DiscogsRequest = (path,params) ->
      fullpath = $cfg.DISCOGS_URL + path
      #IE 9 and older
      if window.XDomainRequest
        deferred = $q.defer()
        url = fullpath
        xdr = new XDomainRequest()
        xdr.open("get",url)
        xdr.onload = -> deferred.resolve xdr.responseText
        xdr.send()
        deferred.promise
      else
        $http.defaults.useXDomain = true
        $http(
            method: "GET"
            params: params
            cache: true
            url: fullpath
        )

    #In this case the API does not serve the year for releases in a label
    Label: (id) ->
      deferred = $q.defer()
      page = 1
      label = {releases:[]}
      pages = -1
      per_page = 500
      getData = ->
        DiscogsRequest("/label/"+id,{'limit':per_page,'page':page})
        .then (data) ->
          data = data.data if data.data
          if page == 1
            pages = $(data).find(".pagination_total")\
                    .html().trim().split(" ")
            pages = parseInt(pages[pages.length-1].replace(",",""))
            pages = Math.ceil(pages/per_page)
            label.name = $(data).find("h1").html()
          rows = $(data).find("#label tr")
          $.each rows, (i,v) ->
            return true if $(this).attr("class") == "headings"
            release = {}
            release.id = $(this).attr("id").substring(1)
            release.is_master = $(this).data("object-type") != "release"
            release.artist = $(this).find(".artist>a").html()
            release.title = $(this).find(".title>a").html()
            release.catno = $(this).find(".catno>span").html()
            release.thumb = $(this).find(".image img").attr("src")
            release.thumb = release.thumb.replace("R-90","R-150")
            release.year = $(this).find(".year").html()
            release.type = "release"
            label.releases.push(release)
          if page >= pages
            deferred.resolve label
          else
            page++
            getData()
      getData()
      deferred.promise

    #used for artists that have too many releases to use the API
    Artist: (id) ->
      deferred = $q.defer()
      page = 1
      artist = {releases:[]}
      pages = -1
      per_page = 500
      getData = ->
        DiscogsRequest("/artist/"+id,{'limit':per_page,'page':page})
        .then (data) ->
          data = data.data if data.data
          if page == 1
            pages = $(data).find(".pagination_total")\
                    .html().trim().split(" ")
            pages = parseInt(pages[pages.length-1].replace(",",""))
            pages = Math.ceil(pages/per_page)
            artist.name = $(data).find("h1").html()
          rows = $(data).find("#artist tr")
          $.each rows, (i,v) ->
            return true if $(this).attr("class") == "credit_header"
            release = {}
            release.id = $(this).attr("id").substring(1)
            release.is_master = $(this).data("object-type") != "release"
            release.artist = $(this).find(".artist>a").html()
            release.title = $(this).find(".title>a").html()
            release.catno = $(this).find(".catno>span").html()
            release.thumb = $(this).find(".image img").attr("src")
            release.thumb = release.thumb.replace("R-90","R-150")
            release.year = $(this).find(".year").html()
            release.type = "release"
            artist.releases.push(release)
          if page >= pages
            deferred.resolve artist
          else
            page++
            getData()
      getData()
      deferred.promise

    #Search API now apparently requires Authentication,
    #unfortunately scraping it has then becomes the better option
    Search: (params) ->
      params['limit'] = 250
      deferred = $q.defer()
      page = 1
      results = {'results': [] }
      pages = -1
      getData = ->
      DiscogsRequest("/search/",params)
      .then (data) ->
        data = data.data if data.data
        rows = $(data).find("#search_results div.card")
        $.each rows, (i,v) ->
            row = $(this)
            release = {}
            release.thumb = row.find(".thumbnail_center img").attr("src")
            release.country = row.find(".card_release_country").html()
            release.format = row.find(".card_release_format").html().split(",")
            release.title = row.find("h4 span[itemprop='name'] a").html()\
                            + " - " + \
                            row.find("h4 .search_result_title").html()
            release.catno = row.find(".card_release_catalog_number").html()
            release.year = row.find(".card_release_year").html()
            release.id = parseInt(row.data("id").substring(1))
            release.type = "release"
            results.results.push(release)
        deferred.resolve results
      deferred.promise
]
