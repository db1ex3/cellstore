'use strict';

/*globals accounting*/

angular.module('main')
.controller('ComparisonSearchCtrl', function($scope, $state, $stateParams, $location, $modal, $backend, conceptMaps, conceptMapKeys, results) {
    $scope.none = 'US-GAAP Taxonomy Concepts';

    $scope.entityIndex = -1;
    $scope.API_URL = $backend.API_URL;

    $scope.conceptMaps = angular.copy(conceptMaps);
    $scope.conceptMaps.push($scope.none);
    $scope.conceptMapKeys = conceptMapKeys;
    $scope.dimensions = [];
    $scope.data = [];
    $scope.columns = [];
    $scope.errornoresults = false;
    $scope.Statistics = {};

    $scope.selection.map = $stateParams.map || $scope.none;
    $scope.selection.concept = ($stateParams.concept ? $stateParams.concept.split(',') : []);
    var src = $location.search();

    Object.keys(src).forEach(function (param) {
        if (param.indexOf(':') !== -1) {
            if (param.substring(param.length - 9, param.length) === '::default') {
                var name = param.substring(0, param.length - 9);
                $scope.dimensions.forEach(function(d) {
                    if (d.name === name)
                    {
                        d.defaultValue = src[param];
                    }
                });
            }
            else {
                $scope.dimensions.push({ name: param, value: src[param] });
            }
            $scope.selection[param] = src[param];
        }
    });

    if (results.FactTable && results.FactTable.length > 0)
    {
        $scope.params = {
            _method: 'POST',
            tag: $scope.selection.tag,
            cik: $scope.selection.cik,
            fiscalYear: $scope.selection.fiscalYear,
            fiscalPeriod: $scope.selection.fiscalPeriod,
            sic: $scope.selection.sic,
            concept: $scope.selection.concept,
            map: ($scope.selection.map !== 'US-GAAP Taxonomy Concepts' ? $scope.selection.map : null),
            rules: ($scope.selection.map !== 'US-GAAP Taxonomy Concepts' ? $scope.selection.map : null),
            token: $scope.token
        };
        $scope.dimensions.forEach(function(dimension) {
            $scope.params[dimension.name] = dimension.value;
            if (dimension.defaultValue)
            {
                $scope.params[dimension.name + '::default'] = dimension.defaultValue;
            }
        });
        $scope.data = results.FactTable;

        $scope.columns.push('xbrl:Concept');
        $scope.columns.push('xbrl:Entity');
        $scope.columns.push('xbrl:Period');
        $scope.columns.push('sec:FiscalPeriod');
        $scope.columns.push('sec:FiscalYear');
        var insertIndex = 3;

        Object.keys($scope.data[0].Aspects).forEach(function (el) {
            switch (el)
            {
                case 'xbrl:Entity':
                    $scope.entityIndex = 1;
                    break;
                case 'xbrl:Concept':
                case 'xbrl:Period':
                case 'sec:Accepted':
                case 'sec:FiscalPeriod':
                case 'sec:FiscalYear':
                    break;
                case 'dei:LegalEntityAxis':
                    $scope.columns.splice(insertIndex, 0, el);
                    insertIndex++;
                    break;
                default:
                    $scope.columns.splice(insertIndex, 0, el);
            }
        });
    }
    $scope.errornoresults = ($scope.data.length === 0);
    $scope.Statistics = results.Statistics;

    $scope.selectMap = function() {
        $scope.selection.concept = [];
    };

    $scope.addConceptKey = function(item) {
        if (item && $scope.selection.concept.indexOf(item) < 0) {
            $scope.selection.concept.push(item);
        }
        $scope.conceptMapKey = '';
    };

    $scope.deleteConceptKey = function(item) {
        $scope.selection.concept.splice($scope.selection.concept.indexOf(item), 1);
    };

    $scope.addDimension = function () {
        var modalInstance = $modal.open({
            templateUrl: 'dimension.html',
            controller: ['$scope', '$modalInstance', function ($scope, $modalInstance) {
                $scope.dimension = {};
                $scope.links = [
                    { 'Name' : 'Legal entity', 'Dimension' : 'dei:LegalEntityAxis', 'Filter' : 'ALL', 'Default' : 'sec:DefaultLegalEntity' },
                    { 'Name' : 'Business segment', 'Dimension' : 'us-gaap:StatementBusinessSegmentsAxis', 'Filter' : 'ALL', 'Default' : 'us-gaap:SegmentDomain' },
                    { 'Name' : 'Geographic area', 'Dimension' : 'us-gaap:StatementGeographicalAxis', 'Filter' : 'ALL', 'Default' : 'us-gaap:SegmentGeographicalDomain' },
                    { 'Name' : 'Scenario', 'Dimension' : 'us-gaap:StatementScenarioAxis', 'Filter' : 'ALL', 'Default' : 'us-gaap:ScenarioUnspecifiedDomain' }
                ];
                $scope.ok = function () {
                    $scope.dimension.attempted = true;
                    if(!$scope.dimension.form.$invalid) {
                        $modalInstance.close({
                            name: $scope.dimension.name,
                            value: $scope.dimension.value,
                            defaultValue: $scope.dimension.defaultValue
                        });
                    }
                };

                $scope.applyLink = function(l) {
                    $scope.dimension.name = l.Dimension;
                    $scope.dimension.value = l.Filter;
                    $scope.dimension.defaultValue = l.Default;
                };

                $scope.cancel = function () {
                    $modalInstance.dismiss('cancel');
                };
            }]
        });

        modalInstance.result.then(function (item) {
            if ($scope.dimensions.indexOf(item) < 0) {
                $scope.dimensions.push(item);
                $scope.selection[item.name] = item.value;
                if (item.defaultValue)
                {
                    $scope.selection[item.name + '::default'] = item.defaultValue;
                }
                $scope.selection.stamp=(new Date()).getTime();
            }
        });
    };

    $scope.deleteDimension = function(item) {
        var name = item.name;
        var def = item.defaultValue;
        $scope.dimensions.splice($scope.dimensions.indexOf(item), 1);
        delete $scope.selection[name];
        if (def)
        {
            delete $scope.selection[name + '::default'];
        }
        $scope.selection.stamp=(new Date()).getTime();
    };

    $scope.submit = function() {
        if ($scope.conceptMapKey) {
            $scope.addConceptKey($scope.conceptMapKey);
        }
        
        if ($scope.selection.concept.length === 0)
        {
            $scope.$emit('alert', 'Warning', 'Please choose concepts to compare.');
            return false;
        }
        $scope.selection.stamp=(new Date()).getTime();
    };
    
    $scope.trimURL = function(url) {
        if (url.length < 40) {
            return url;
        }
        return url.substr(0, 10) + '...' + url.substr(url.length - 30);
    };

    $scope.trim = function(item) {
        return angular.copy(item).splice(4, item.length - 5);
    };

    $scope.clear = function(item) {
        return item.replace('iso4217:', '').replace('xbrli:', '');
    };

    $scope.showText = function(html) {
        $scope.$emit('alert', 'Text Details', html);
    };

    $scope.showNumber = function(value) {
        return accounting.formatNumber(value);
    };

    $scope.isBlock = function(string) {
        if (!string) {
            return false;
        }
        return string.length > 60;
    };

    $scope.getUrl = function(format) {
        var str = $backend.API_URL + '/_queries/public/api/facts.jq';
        var params = angular.copy($scope.params);
        if (format) {
            params.format = format;
        }
        var qs = $scope.wwwFormUrlencoded(params);
        if (qs) {
            str += '?' + qs;
        }
        return str;
    };
});
