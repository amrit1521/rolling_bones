APP = window.APP
APP.Controllers.controller('HuntsColoradoFallTurkey', ['$scope', '$location', '$routeParams', 'Hunt', 'HuntChoice', 'HuntOption', 'Storage', ($scope, $location, $routeParams, Hunt, HuntChoice, HuntOption, Storage) ->
  $scope.init = ->
    #$scope.setHuntType '{"year":"' + moment().format('YYYY') + '", "priv_code":"481", "species":"4", "app_type":"A", "prefix":"E"}'
    $scope.setHuntType '{"message": "Please complete the hunttype"}'
    alert "Please complete the hunttype"

  $scope.init.call(@)
])
