'use strict';

/*globals recurly*/

angular.module('secxbrl')
    .controller('BillingCtrl', function($scope, $modal, API, apiStatistics) {
        $scope.calls = {
            label: apiStatistics.calls,
            percentage: (apiStatistics.calls / 1000),
            from: new Date(apiStatistics.fromDate),
            to: new Date(apiStatistics.toDate) - 1
        };

    });
