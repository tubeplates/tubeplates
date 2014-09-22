"use strict"

app.directive "discogsSection",[
  "$window"
  ($window) ->
    restrict: "A"
    link: (scope, elem, attrs) ->
      resize = ->
        used_height = angular.element("#playersection").height()\
                    + angular.element("#search_form").height()
        elem.height angular.element("html").height() - used_height - 60
      angular.element(document).ready -> resize()
      angular.element($window).resize -> resize()
]

app.directive "loadingSpinner",[
  "$timeout"
  ($timeout) ->
    restrict: "AE"
    scope:
      src: "="
      speed: "="
      height: "="
      width: "="
      totalFrames: "="
      frameWidth: "="
      ngShow: "="

    link: (scope, elem, attrs) ->

        global  =
          cTotalFrames : parseInt(attrs.totalFrames) or 18
          cFrameWidth : parseInt(attrs.width) or 128
          cIndex : 0
          cXpos : 0
          SECONDS_BETWEEN_FRAMES : 0

        img = elem[0]

        cSpeed = parseInt(attrs.speed) or 2
        cWidth = parseInt(attrs.width) or 128
        cHeight = parseInt(attrs.height) or cWidth
        cImageSrc = attrs.src

        FPS = Math.round(100 / cSpeed)
        global.SECONDS_BETWEEN_FRAMES = 1 / FPS

        genImage = new Image()
        genImage.src = cImageSrc

        genImage.onload = ->
            img.style.backgroundImage = "url(" + cImageSrc + ")"
            img.style.width = cWidth + "px"
            img.style.height = cHeight + "px"
            spin()

        spin = ->
          return if scope.$$destroyed
          if scope.ngShow
              global.cXpos += global.cFrameWidth
              global.cIndex += 1
              if global.cIndex >= global.cTotalFrames
                  global.cXpos = 0
                  global.cIndex = 0
              img.style.backgroundPosition = (-global.cXpos) + "px 0"
          $timeout(spin, global.SECONDS_BETWEEN_FRAMES * 1000)
]

app.directive "sortArrow", ->
  transclude: true
  scope:
    name: "@"

  template: """
      <div ng-class="{angularTableDefaultSortArrowDescending :
                      $parent.sorted('{{name}}','desc'),
                      angularTableDefaultSortArrowAscending :
                      $parent.sorted('{{name}}','asc')
                      }"/>
  """
  replace: true
  restrict: "E"

app.directive "autofocus", [
  "$document"
  ($document) ->
    return link: ($scope, $element, attrs) ->
      setTimeout (->
        $element[0].focus()
        return
      ), 100
      return
]
