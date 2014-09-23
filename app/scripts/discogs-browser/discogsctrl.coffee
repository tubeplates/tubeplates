"use strict"

#This controller serves
#everything that has to do with the discogs browser
app.controller "DiscogsCtrl", [
    "$scope"
    "$rootScope"
    "$timeout"
    "$discogs"
    "$router"
    "$discogsconfig"
    ($scope,$rootScope,$timeout,$discogs,$router,$cfg) ->

        #VARIABLES
        $scope.router = new $router()
        $scope.categories = $cfg.categories
        $scope.coverimg = ""
        $scope.history = {}
        $scope.searchParams = {q:'',type: $scope.categories[0]}
        $scope.current_view = ""
        $scope.data = {}
        $rootScope.fullscreen = false

        $scope.togglefullScreen = ->
            $rootScope.fullscreen =! $rootScope.fullscreen

        init_data = -> { sortstate:{ map:{} }}

        for i,category of $scope.categories
            $scope.data[category] = init_data()
            $scope.data[category+"_search"] = init_data()

        #LISTENERS
        $rootScope.$on 'player.trackNotFound', ->
            for i, row of $scope.data[$scope.current_view].content
                if row.rowSelected
                    row.notFound = true
                    break
            $scope.nextTrack()

        $rootScope.$on 'player.focusPlaylist', ->
            for i, row of $scope.data[$scope.current_view].content
                delete row.rowSelected

        $rootScope.$on 'player.donePlaying', -> $scope.nextTrack()

        #METHODS

        $scope.loading = ->
            return false if not $scope.current_view
            return $scope.data[$scope.current_view].loading

        $scope.updateTitle = (title) ->
            return if not $scope.current_view
            $rootScope.title = "TP::" + title

        $scope.showAbout = -> Object.keys($scope.router.dict()).length == 0

        $scope.tabActive = (name) ->
            $scope.current_view == name\
            and not $scope.data[name].loading\
            and not $scope.no_results()

        $scope.no_results = ->
            current_data = $scope.data[$scope.current_view]
            return if not current_data
            not current_data.loading and current_data.content.length is 0

        $scope.sorted = (col,order) ->
            return if not $scope.current_view or $scope.current_view =="loading"
            mapval = if order == "asc" then true else false
            sortstate = $scope.data[$scope.current_view].sortstate
            val = sortstate.expression == col and sortstate.map[col] == mapval
            return val

        $scope.extraArtists = () ->
            return if not $scope.current_view
            current_data = $scope.data[$scope.current_view].content
            for i,el of current_data
                return true if el.extraartists
            return false

        $scope.Duration = () ->
            return if not $scope.current_view
            current_data = $scope.data[$scope.current_view].content
            for i,el of current_data
                return true if el.duration
            return false

        $scope.search = ->
            params =
                q: $scope.searchParams.q
                type: $scope.searchParams.type
            $scope.router.changeParams params

        $scope.viewRelease = (id,is_master) ->
            params = release: id
            if is_master
               params.master = true
            $scope.router.changeParams params

        $scope.viewArtist = (id) ->
            params = artist: id
            $scope.router.changeParams params

        $scope.viewLabel = (id) ->
            params = label: id
            $scope.router.changeParams params

        $scope.prevSearch = ->
            type = $scope.history.search.type
            $scope.current_view = type + "_search"
            params =
                q: $scope.history.search.query
                type: type
            $scope.router.changeParams params,true
            $scope.updateTitle("Search::" + $scope.history.search.query)

        $scope.prevRelease = ->
            $scope.current_view = "release"
            params = release: $scope.history.release.id
            $scope.router.changeParams params,true
            $scope.updateTitle($scope.history.release.name)

        $scope.prevArtist = ->
            $scope.current_view = "artist"
            params = artist: $scope.history.artist.id
            $scope.router.changeParams params,true
            $scope.updateTitle($scope.history.artist.name)

        $scope.prevLabel = ->
            $scope.current_view = "label"
            params = label: $scope.history.label.id
            $scope.router.changeParams params,true
            $scope.updateTitle($scope.history.label.name)

        $scope.setCoverimg = (img) ->
            $scope.coverimg = img

        $scope.nextTrack = ->
            playlist = $scope.data.release.content
            now_playing = -1
            for i,item of playlist
                if item.rowSelected
                   now_playing = parseInt(i)
                   delete item.rowSelected
                   break
            if now_playing >= 0 && playlist.length > now_playing
                row = playlist[now_playing+1]
                row.rowSelected = true
                track =
                    name: row.title
                    artist: row.artist
                    duration: row.duration
                $rootScope.$broadcast("playTrack",track)

        $scope.sort = (col,order,data) ->
            if data
              current_data = data
            else
              current_data = $scope.data[$scope.current_view]
            current_data.sortstate.expression = col
            map = current_data.sortstate.map
            map[col] = if map[col] then !map[col] else true
            current_data.content.sort (a,b) ->
                  first = eval("a." + col)
                  second = eval("b." + col)
                  return 0 if first == second
                  return -1 if first < second
                  return 1 if first > second
            current_data.content.reverse() if not map[col] or order is "desc"

        $scope._search = ->
            return if not $scope.searchParams.q
            $scope.coverimg = ""
            query = $scope.searchParams.q
            type = $scope.searchParams.type
            search = $discogs.Search {q: query,type: type}
            $scope.current_view = type + "_search"
            $scope.data[type + "_search"] = current_data = init_data()
            current_data.content = []
            current_data.loading = true
            $scope.searchParams.q = ""
            $scope.history.search =
                    query: query
                    type: type
            search.$promise.then (search) ->
                current_data.loading = false
                current_data.content = search.results
                $scope.updateTitle("Search::" + $scope.history.search.query)

        $scope._viewRelease = (id,is_master,trackno) ->
               if is_master
                 release = $scope._viewItem("master",{id: id}).$promise
               else
                 release = $scope._viewItem("release",{id: id}).$promise


        $scope._viewArtist = (id) ->
               $scope._viewItem("artist",{id: id}).$promise
               .then (item) ->
                   $scope.sort("id","desc",$scope.data.artist)
                   $scope.sort("year","desc",$scope.data.artist)

        $scope._viewLabel = (id) ->
               $scope._viewItem("label",{id: id}).$promise
               .then (item) ->
                   $scope.sort("id","desc",$scope.data.label)
                   $scope.sort("year","desc",$scope.data.label)

        $scope._viewItem = (item_type,params) ->
               if item_type is "release"
                  service = $discogs.Release
                  data_name = "tracklist"
               else if item_type is "master"
                  service = $discogs.Master
                  data_name = "tracklist"
                  item_type = "release"
               else if item_type is "artist"
                  service = $discogs.ArtistReleases
                  data_name = "releases"
               else if item_type is "label"
                  service = $discogs.LabelReleases
                  data_name = "releases"
               d = service(params)
               $scope.coverimg = ""
               $scope.data[item_type] = init_data()
               $scope.data[item_type].content = []
               $scope.current_view = item_type
               $scope.data[item_type].loading = true
               $scope.history[item_type] =
                    name: "..."
                    id: params.id
               d.$promise.then (item) ->
                   $scope.data[item_type].content = item[data_name]
                   $scope.data[item_type].loading = false
                   $scope.history[item_type].name = item.title or item.name
                   $scope.updateTitle($scope.history[item_type].name)
               d

        #URL ROUTING

        $scope.router.watch 'q', (value) ->
            $rootScope.title = "TubePlates"
            return unless value
            $scope.searchParams.q = value

        $scope.router.watch 'type', (value) ->
            $rootScope.title = "TubePlates"
            return unless value
            for index,category of $scope.categories
                if category == value
                   $scope.searchParams.type = category
                   return

        $scope.router.done ->
            params = $scope.router.dict()
            if "release" of params
                $scope._viewRelease(params.release,
                                    "master" of params,
                                    params.track)
            else if "artist" of params
                $scope._viewArtist(params.artist)
            else if "label" of params
                $scope._viewLabel(params.label)
            else if "q" of params
                $scope._search()

        #TABLE FUNCTIONS
        $scope.tableResizeEvents = -> [ $rootScope.fullscreen ]

        info_clean = (data) ->
            re = new RegExp(/\[|\]|[a-z]\=|\(|\)/g)
            data.replace re,""

        $scope.artistInfo = (row) ->
            $discogs.Artist({id: row.id}).$promise
            .then ((data) ->
                $scope.covercaption = if data.profile \
                                      then info_clean data.profile\
                                      .substring(0,200)\
                                      else ""
            ), (error) ->
                $scope.covercaption = ""

        $scope.labelInfo = (row) ->
            $discogs.Label({id: row.id}).$promise
            .then (data) ->
                $scope.covercaption = if data.profile \
                                      then info_clean data.profile\
                                      .substring(0,200)\
                                      else ""


        $scope.selectRow = (row) ->
            return if not row
            content = $scope.data[$scope.current_view].content
            for i,c of content
                delete c.rowSelected if c.rowSelected
            row.rowSelected = true

        $scope.t_viewRelease = ($event,row) ->
            return if not row
            $scope.selectRow(row)
            $scope.viewRelease(row.id,row.is_master)

        $scope.t_viewArtist = ($event,row) ->
            return if not row
            $scope.selectRow(row)
            $scope.viewArtist(row.id)

        $scope.t_viewLabel = ($event,row) ->
            return if not row
            $scope.selectRow(row)
            $scope.viewLabel(row.id)

        $scope.playTrack = (artist,title,duration,extraartists) ->
            track =
                name: title
                artist: artist
                extraartists: extraartists
                duration: duration
            $rootScope.$broadcast("playTrack",track)

        $scope.t_playTrack = ($event,row) ->
            return if not row
            $scope.selectRow(row)
            $scope.playTrack(row.artist, row.title,
                            row.duration, row.extraartists)

        $scope.t_addToPlaylist= ($event,row) ->
            return if not row
            console.log(row)
            $event.stopPropagation()
            if row.type == "release"
               service = if row.is_master then $discogs.Master else $discogs.Release
               service({id: row.id}).$promise.then (release)->
                  for i,release of release.tracklist
                      $rootScope.$broadcast("addTrackToPlaylist",
                                            release.title,
                                            release.artist)
            else
                $rootScope.$broadcast("addTrackToPlaylist",
                                      row.title,
                                      row.artist)
]
