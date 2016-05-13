"use strict"

#This controller serves the playlist and the YouTube player
app.controller "PlayerCtrl", [
  "$scope"
  "$rootScope"
  "$timeout"
  "$youtube"
  "$ytsearch"
  "$playlist"
  "$ytTrackFinder"
  ($scope,$rootScope,$timeout,
   $youtube, $ytsearch,
   $playlist, $ytTrackFinder) ->

      #VARIABLES
      $youtube.playerHeight = $youtube.playerWidth = ""
      $scope.videoID = ""
      $scope.playlist = new $playlist()
      $scope.playing = false
      $scope.playlist_focused = false
      $scope.sortableOptions =
        oldpos : -1
        start: (e, ui) ->
          $scope.sortableOptions.oldpos = ui.item[0].rowIndex
        stop: (e, ui) ->
          oldpos = $scope.sortableOptions.oldpos
          newpos = ui.item[0].rowIndex
          if oldpos is $scope.playlist.playing
            $scope.playlist.playing = newpos
          else if oldpos < $scope.playlist.playing\
               and newpos >= $scope.playlist.playing
            $scope.playlist.playing--
          else if oldpos > $scope.playlist.playing\
               and newpos <= $scope.playlist.playing
            $scope.playlist.playing++

      #METHODS
      $scope.nextTrack = ->
        $scope.playlist_focused = true
        $rootScope.$broadcast 'player.focusPlaylist'
        playItem $scope.playlist.nextItem()

      $scope.prevTrack = ->
        $scope.playlist_focused = true
        $rootScope.$broadcast 'player.focusPlaylist'
        playItem $scope.playlist.prevItem()

      $scope.changeTrack = (index) ->
        $scope.playlist_focused = true
        $rootScope.$broadcast 'player.focusPlaylist'
        playItem $scope.playlist.playItem(index)

      #LISTENERS
      $scope.$on "youtube.player.ready", ->
        $youtube.player.setPlaybackQuality("hd720")
        $youtube.player.playVideo()

      $scope.$on "youtube.player.ended", ->
        if $scope.playlist_focused
            $scope.nextTrack()
        else
            $rootScope.$broadcast 'player.donePlaying'

      $scope.$on 'trackNotFound', ->
        $scope.playlist.items[$scope.playlist.playing].notfound = true
        $scope.nextTrack()

      $rootScope.$on 'playTrack', (event,track) ->
        $scope.playlist_focused = false
        $scope.playlist.playing = -1
        playItem track

      $rootScope.$on 'addTrackToPlaylist', (event,name,artist,duration) ->
        $scope.playlist.addTrack name,artist,duration

      #HELPERS
      playItem = (item) ->
        return if not item or $scope.playing
        $scope.videoID = ""
        $scope.playing = true
        artists = item.artist
        if item.extraartists
          extraartists = artists.slice(1)\
          .concat(item.extraartists).join(",")
        else
          extraartists = artists.slice(1).join(",")

        track =
          artist: artists[0].name
          extraartists: extraartists
          title: item.name
          duration: item.duration
        $ytTrackFinder.Find(track.artist,track.title,
                            track.duration,track.extraartists)
        .then (entry) ->
          $scope.playing = false
          if entry
            $timeout (->
              $scope.videoID = entry.id
            )
          else if $scope.playlist_focused
            $scope.$broadcast 'trackNotFound'
          else
            $rootScope.$broadcast 'player.trackNotFound'
]
