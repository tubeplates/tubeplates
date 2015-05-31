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

    convert_time = (duration) ->
        total = 0
        hours = duration.match(/(\d+)H/)
        minutes = duration.match(/(\d+)M/)
        seconds = duration.match(/(\d+)S/)
        if hours
            total += parseInt(hours[1]) * 3600
        if minutes
            total += parseInt(minutes[1]) * 60
        if seconds
            total += parseInt(seconds[1])
        total

    entryID = (entry) ->
      entry.id.videoId

    Find: (artist,title,duration,extraartists) ->
      deferred = $q.defer()
      seconds = durationToSeconds duration
      $ytsearch.Search(artist + " - " + title)
      .then (data) ->
        if typeof(data) == "string"
          data = $.parseJSON(data)
        entries = data.data.items
        highest = 0
        non_music_cats = [
          "2" #Autos
          "23" #Comedy
          "27" #Education
          "26" #Howto
          "20" #Gaming
          "25" #News
          "29" #Activism
          "25" #Pets
          "28" #Science
          "17" #Sports
          "19" #Travel
        ]
        for index,entry of entries
          skipentry = false
          category = entry.categoryID
          for cat in non_music_cats
            if category == cat
              skipentry = true
          if skipentry
            entry.heuristic = 0
            continue
          entry.heuristic = 0
          entry_title = entry.snippet.title
          entry_duration = convert_time entry.duration
          entry_duration = parseInt(entry_duration)

          titleScore = $r.trackTitleScore artist,title,entry_title
          extraArtistsScore = $r.extraArtistsScore extraartists,entry_title
          commonWords = $r.commonWordsScore title,entry_title
          extraartists = extraartists or ""
          noncommonWords = $r.nonCommonWordsScore(
                              artist + " " + extraartists,
                              title,
                              entry_title)
          durationDifferenceRatio = $r.durationDifferenceRatio(
                                entry_duration,
                                seconds)
          trackTypeScore = $r.trackTypeScore title,entry_title
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
