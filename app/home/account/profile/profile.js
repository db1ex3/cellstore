/*global moment:false */
'use strict';

angular.module('secxbrl')
    .controller('ProfileCtrl', function($scope, API) {
        $scope.attempted = false;
        $scope.firstname = $scope.user.firstname;
        $scope.lastname = $scope.user.lastname;

        $scope.update = function() {
            $scope.attempted = true;

            $scope.$broadcast('autocomplete:update');

            if(!$scope.updateProfileForm.$invalid) {
                $scope.loading = true;
                API.Users.editUser({ userid: $scope.user.id, email: $scope.user.email, firstname: $scope.firstname, lastname: $scope.lastname, token: $scope.token })
                    .then(
                    function() {
                        $scope.$emit('alert', 'Success', 'Your profile information has been updated.');
                        $scope.user.firstname = $scope.firstname;
                        $scope.user.lastname = $scope.lastname;
                        $scope.attempted = false;
                        $scope.loading = false;
                    },
                    function(response) {
                        $scope.$emit('error', response.status, response.data);
                        $scope.loading = false;
                    });
            }
        };

        $scope.reset = function() {
            $scope.firstname = $scope.user.firstname;
            $scope.lastname = $scope.user.lastname;
            $scope.attempted = false;
        };
    });