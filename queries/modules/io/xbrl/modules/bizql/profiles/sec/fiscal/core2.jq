jsoniq version "1.0";

module namespace fiscal-core2 = "http://xbrl.io/modules/bizql/profiles/sec/fiscal/core2";

import module namespace entities = "http://xbrl.io/modules/bizql/entities";
import module namespace archives = "http://xbrl.io/modules/bizql/archives";

import module namespace sec-fiscal = "http://xbrl.io/modules/bizql/profiles/sec/fiscal/core";

(:~
 : Joker for the latest fiscal years.
 :)
declare variable $fiscal-core2:LATEST_FISCAL_YEAR as integer := 1;


(:~
 : <p>Return a distinct set of companies identified by either
 :   CIKs, tags, tickers, or sics.</p>
 : 
 : @param $ciks a set of CIKs.
 : @param $tags a set of tags (ALL retrieves all companies).
 : @param $tickers a set of tickers.
 : @param $sics a set of SIC codes.
 :
 : @return the companies with the given identifiers, tags, tickers, or sic codes.
 :)
declare function fiscal-core2:filings(
    $entities-or-eids as item*,
    $fiscal-periods as string*,
    $fiscal-years as integer*,
    $archives-or-aids as item*) as object*
{
    let $entities := entities:entities($entities-or-eids)
    return
        if(exists(index-of($fiscal-years, $fiscal-core2:LATEST_FISCAL_YEAR)))
        then
            for $entity in $entities
            return
            fiscal-core2:latest-filings($entity, $fiscal-periods)
        else
            let $fiscal-years as integer* :=
                $fiscal-years[$$ ne $fiscal-core2:LATEST_FISCAL_YEAR]
            return
                sec-fiscal:filings-for-entities-and-fiscal-periods-and-years($entities, $fiscal-periods, $fiscal-years),
    archives:archives($archives-or-aids)
};

declare function fiscal-core2:latest-filings(
    $entities as object*,
    $fiscal-periods as string*) as object*
{
    for $entity in $entities
    for $fiscal-period in $fiscal-periods 
    let $latest-fiscal-year :=
        sec-fiscal:latest-reported-fiscal-period($entity, $fiscal-period).year
    return sec-fiscal:filings-for-entities-and-fiscal-periods-and-years(
        $entity,
        $fiscal-period,
        $latest-fiscal-year cast as integer?
    )
};

declare function fiscal-core2:filter-override(
    $entities-or-eids as item*,
    $fiscal-years as integer*,
    $fiscal-periods as string*,
    $archives-or-aids as item*
) as object?
{
    let $entities := entities:entities($entities-or-eids)
    let $aids := archives:aid($archives-or-aids)
    let $latest-filings := fiscal-core2:latest-filings($entities, $fiscal-periods)
    return
    switch(true)
    case count($aids) gt 0 return {
        "sec:Archive" : {
            Type: "string",
            Domain : [ $aids ]
        },
        "sec:FiscalPeriod" : {|
            {
                Type: "string",
                Domain: [ $fiscal-periods ]
            }[exists($fiscal-periods) and empty(index-of($fiscal-periods, $sec-fiscal:ALL_FISCAL_PERIODS))]
        |}
    }
    case exists(index-of($fiscal-years, $fiscal-core2:LATEST_FISCAL_YEAR))
    return {
        "sec:Archive" : {
            Type: "string",
            Domain : [archives:aid($latest-filings)]
        },
        "sec:FiscalPeriod" : {|
            {
                Type: "string",
                Domain: [ $fiscal-periods ]
            }[exists($fiscal-periods) and empty(index-of($fiscal-periods, $sec-fiscal:ALL_FISCAL_PERIODS))]
        |}
    }
    case exists(($entities, $fiscal-years, $fiscal-periods))
    return {
        "xbrl:Entity" : {|
            {
                Type: "string",
                Domain: [ $entities._id ]
            }[exists($entities)]
        |},
        "sec:FiscalYear" :
            let $fiscal-years as integer* :=
                $fiscal-years[$$ ne $fiscal-core2:LATEST_FISCAL_YEAR]
            return {|
                {
                    Type: "integer",
                    Domain: [ $fiscal-years ]
                }[exists($fiscal-years) and empty(index-of($fiscal-years, $sec-fiscal:ALL_FISCAL_YEARS))]
            |},
        "sec:FiscalPeriod" : {|
            {
                Type: "string",
                Domain: [ $fiscal-periods ]
            }[exists($fiscal-periods) and empty(index-of($fiscal-periods, $sec-fiscal:ALL_FISCAL_PERIODS))]
        |},
        "sec:Archive" : {}
    }
    default return ()
};

