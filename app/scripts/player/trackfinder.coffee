"use strict"

###
A service for searching YouTube
###
app.factory "$ytTrackFinder", [
  "$q"
  "$ytsearch"
  "$relevance"
  ($q,$ytsearch,$r) ->

    durationToSeconds = (dstr) ->
      return if not dstr
      dstr = parseInt((dstr\
                .split(":")\
                .reverse()\
                .map( (t,i) -> t*Math.pow(60,i)))\
                .reduce (a,b) -> a+b)

    entryID = (entry) ->
      id_container = entry.id.$t
      index = id_container.indexOf "video:"
      id = id_container.substring(index+6)

    Find: (artist,title,duration,extraartists) ->
      deferred = $q.defer()
      seconds = durationToSeconds duration
      $ytsearch.Search(artist + " - " + title)
      .then (data) ->
        if typeof(data) == "string"
          data = $.parseJSON(data)
        entries = data.data.feed.entry
        highest = 0
        non_music_cats = [
          "Autos"
          "Comedy"
          "Education"
          "Howto"
          "Gaming"
          "News"
          "Activism"
          "Pets"
          "Science"
          "Sports"
          "Travel"
        ]
        for index,entry of entries
          skipentry = false
          for i,access of entry.yt$accessControl
            if access.action == "embed"
              if access.permission == "denied"
                skipentry = true
          category = entry.media$group.media$category[0].$t
          for cat in non_music_cats
            if category.indexOf(cat) != -1
              skipentry = true
          if skipentry
            entry.heuristic = 0
            continue
          entry.heuristic = 0
          entry_title = entry.title.$t
          entry_duration = entry.media$group.yt$duration.seconds
          entry_duration = parseInt(entry_duration)

          titleScore = $r.trackTitleScore artist,title,entry_title
          extraArtistsScore= $r.extraArtistsScore extraartists,entry_title
          commonWords = $r.commonWordsScore title,entry_title
          extraartists = extraartists or ""
          noncommonWords = $r.nonCommonWordsScore(
                              artist + " " + extraartists,
                              title,
                              entry_title)
          trackTypeScore = $r.trackTypeScore title,entry_title
          durationDifferenceRatio = $r.durationDifferenceRatio(
                                entry_duration,
                                seconds)
          h = 0
          if titleScore > 0
            h++
            if commonWords >= 10
              h++
              if trackTypeScore >= 10
                h++
                if noncommonWords >= 10
                  h++
                  if extraArtistsScore>= 10
                    h++
                    if 0.5 <= durationDifferenceRatio <= 1.1
                      h++
          h = 0 if commonWords == 0\
                or 0.5 <= durationDifferenceRatio >= 2
          entry.heuristic = h
          entry.index = index
          highest = entry.heuristic if entry.heuristic > highest

        if entries and entries.length > 0
          candidates = []
          for i,entry of entries
            if entry.heuristic == highest
              candidates.push entry
          candidates = candidates.sort (a,b) ->
            a.index - b.index
          candidates[0].id = entryID candidates[0]
          winning_entry = candidates[0]
          if winning_entry.heuristic > 0
            deferred.resolve winning_entry
          else
            deferred.resolve null
        else
          deferred.resolve null
      deferred.promise
]
