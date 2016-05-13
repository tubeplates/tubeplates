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
]
