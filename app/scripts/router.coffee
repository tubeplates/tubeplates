"use strict"

###
Simple class that holds an array of playlist items
and the index of the currently playing item
###
angular.module("TubePlates")
.factory "$router", [
  "$location"
  "$rootScope"
  ($location,$rootScope) ->
    class Router
      constructor: () ->
        @variables = {}
        @callback = ->
        @noAction = false
        self = @
        $rootScope.$watch (->
            $location.search()
        ), (newValue, oldValue) ->
          if self.noAction
            self.noAction = false
            return
          for variable,action of self.variables
            action($location.search()[variable])
          self.callback()

      watch: (variable,action) ->
        @variables[variable] = action

      done: (callback) ->
        @callback = callback

      setKey: (key,value) ->
        $location.search key, value

      removeKey: (key) ->
        $location.search key, null

      dict: (key) ->
        $location.search()

      changeParams: (params,noAction) ->
        if noAction
          @noAction = true
        $location.search params
]
