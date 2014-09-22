"use strict"

app.factory "$playlist", () ->
  ###
  Simple class that holds an array of playlist items
  and the index of the currently playing item
  ###
  class Playlist
    constructor: () ->
      @playing = -1
      @items = []

    playItem : (index) =>
      @playing = index
      @items[index]

    prevItem : () =>
      if @playing > 0
        @playing--
        @items[@playing]
      else
        null

    nextItem : () =>
      if @playing < @items.length-1
        @playing++
        @items[@playing]
      else
        @playing = -1
        null

    clear: () =>
      @constructor()

    addTrack: (name, artist) =>
      track =
        name: name
        artist: artist
      @items.push track

    removeItem : (index) =>
      item = @items[index]
      @items.splice index,1
      if @playing == -1
        return
      else if index < @playing
        @playing--
      else if index == @playing
        @playing = -1
      item
