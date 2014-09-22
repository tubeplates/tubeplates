"use strict"

###
This service contains functions
that calculate various scores
of a youtube search to match various track info
###
app.factory "$relevance", [
  "$resource"
  "$q"
  ($q, $http) ->

    stringNOR = (first, second, string) ->
        lowerfirst = first.toLowerCase()
        lowersecond = second.toLowerCase()
        lowerstring = string.toLowerCase()
        firstcontains = lowerfirst.indexOf(lowerstring) isnt -1
        secondcontains = lowersecond.indexOf(lowerstring) isnt -1
        firstcontains is secondcontains

    tracktypes = [
             "live"
              "vocal"
              "remix"
              "mix"
              "vip"
              "instrumental"
              "mix"
              "cover"
              "refix"
              "edit"
              "tour"
              "retake"
              "alternate"
              "edit"
              "album"
              "explicit"
              "extended"
              "/",
              "version"
              "@"
              "playing"
              "acoustic"
              "festival"
              "radio"
              "freestyle"
              "tutorial"
              "review"
              "vs"
              "singing"
              "slowed"
              "chopped"
    ]

    alphaNumeric = (string) ->
        return string.replace(".","").replace(/\W+/g, " ").toLowerCase()

    flattenString = (string) ->
        return alphaNumeric(string).replace(RegExp(" ", "g"), "")

    trackTitleScore : (artist,title,result_title) ->
        score = 0
        f_title = flattenString title
        f_resultTitle = flattenString result_title
        f_artist = flattenString artist
        score += 1 if f_resultTitle.indexOf(f_artist) != -1
        score += 2 if f_resultTitle.indexOf(f_title) != -1
        return (score / 3)*10

    extraArtistsScore: (extraartists,result_title) ->
        words = {}
        return 0 if not extraartists
        flat_artists = alphaNumeric(extraartists)
        flat_result = alphaNumeric(result_title)
        artists = 0
        for i,word of flat_result.split(" ")
            if flat_artists.indexOf(word) != -1
               if not words[word.trim()]
                  artists++
                  words[word.trim()] = true
        return (artists/(flat_artists.split(" ").length))*10

    commonWordsScore : (title,result) ->
        flat_title = alphaNumeric(title)
        flat_result = alphaNumeric(result)
        count = 0
        words = {}
        for index,titleword of flat_title.split(" ")
            for index,resultword of flat_result.split(" ")
                if (titleword.trim().length > 1\
                 or flat_title.split(" ").length == 1)\
                 and titleword.trim() == resultword.trim()
                   if not words[titleword.trim()]
                       count++
                       words[titleword.trim()] = true
        return (count / flat_title.split(" ").length)*10

    nonCommonWordsScore: (artist,title,result) ->
        skip_words = ["hq","720p","hq","video","official","by","ft"]
        flat_artist = alphaNumeric(artist)
        flat_title = alphaNumeric(title)
        flat_result = alphaNumeric(result)
        noncommon = 0
        for word,i in flat_result.split(" ")
            continue if skip_words.indexOf(word) != -1
            if flat_title.indexOf(word) == -1\
            and flat_artist.indexOf(word) == -1
               noncommon++
        max = flat_result.split(" ").length + flat_title.split(" ").length\
            + flat_artist.split(" ").length
        score = 10-( noncommon/max)
        return 0 if score < 0
        return score

    trackTypeScore : (first,second) ->
        score = 0
        for k,v of tracktypes
            if stringNOR first.toLowerCase(),second.toLowerCase(),v
              score += 1
        return (score / tracktypes.length)*10

    durationDifferenceRatio: (first,second) ->
        return first/second
]
