"use strict"

###
Constants and configuration
for everything that involves Discogs
###
app.factory "$discogsconfig", [
  () ->
    API_URL : "//api.discogs.com"
    DISCOGS_URL : "http://www.discogs.com"
    categories : ['release', 'artist', 'label']
]
