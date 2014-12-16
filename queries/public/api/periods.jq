import module namespace config = "http://apps.28.io/config";
import module namespace api = "http://apps.28.io/api";
import module namespace session = "http://apps.28.io/session";

import module namespace csv = "http://zorba.io/modules/json-csv";

import module namespace archives = "http://28.io/modules/xbrl/archives";
import module namespace entities = "http://28.io/modules/xbrl/entities";

import module namespace companies = "http://28.io/modules/xbrl/profiles/sec/companies";
import module namespace filings = "http://28.io/modules/xbrl/profiles/sec/filings";

import module namespace japan = "http://28.io/modules/xbrl/profiles/japan/core";

import module namespace fiscal-core = "http://28.io/modules/xbrl/profiles/sec/fiscal/core";

(: Query parameters :)
declare  %rest:case-insensitive                 variable $token         as string? external;
declare  %rest:env                              variable $request-uri   as string  external;
declare  %rest:case-insensitive                 variable $format        as string? external;
declare  %rest:case-insensitive %rest:distinct  variable $eid           as string* external;
declare  %rest:case-insensitive %rest:distinct  variable $cik           as string* external;
declare  %rest:case-insensitive %rest:distinct  variable $tag           as string* external;
declare  %rest:case-insensitive %rest:distinct  variable $ticker        as string* external;
declare  %rest:case-insensitive %rest:distinct  variable $sic           as string* external;
declare  %rest:case-insensitive %rest:distinct  variable $fiscalYear    as string* external := "ALL";
declare  %rest:case-insensitive %rest:distinct  variable $fiscalPeriod  as string* external := "ALL";
declare  %rest:case-insensitive %rest:distinct  variable $aid           as string* external;
declare  %rest:case-insensitive                 variable $profile-name  as string  external := $config:profile-name;

session:audit-call($token);

(: Post-processing :)
let $format as string? := api:preprocess-format($format, $request-uri)
let $fiscalYear as integer* := api:preprocess-fiscal-years($fiscalYear)
let $fiscalPeriod as string* := api:preprocess-fiscal-periods($fiscalPeriod)
let $tag as string* := api:preprocess-tags($tag)

(: Object resolution :)
let $entities :=
    switch($profile-name)
    case "sec" return companies:companies(
        $cik,
        $tag,
        $ticker,
        $sic)
    case "japan" return
            if(exists($eid)) then entities:entities($eid)
                             else if($tag = "ALL") then entities:entities() else ()
    default return ()
let $archives as object* :=
    switch($profile-name)
    case "sec" return fiscal-core:filings(
        $entities,
        $fiscalPeriod,
        $fiscalYear,
        $aid)
    case "japan" return japan:filings($entities, $fiscalYear, $fiscalPeriod, $aid)
    default return
        if(exists($eid)) then archives:archives-for-entities($eid)
                         else archives:archives()
let $periods :=
    switch($profile-name)
    case "sec" return
        for $f in filings:summaries($archives) 
        order by $f.Accepted descending
        return $f
    case "japan" return
      for $a in $archives
      group by $fy := $a.Profiles.JAPAN.DocumentFiscalYearFocus, $fp := $a.Profiles.JAPAN.DocumentFiscalPeriodFocus
      order by $fy descending, $fp
      return { FiscalYear: $fy, FiscalPeriod: $fp }
    default return ()

let $result := { "Periods" : [ $periods ] }
let $comment :=
{
    NumPeriods: count($periods)
}
let $serializers := {
    to-xml : function($res as object) as node() {
        switch($profile-name)
        case "sec"
        case "japan" return
            <Periods>{
                for $period in $res.Periods[]
                return <Period fiscalYear="{$period.FiscalYear}" fiscalPeriod="{$period.FiscalPeriod}"/>
            }</Periods>
        default return ()
    },
    to-csv : function($res as object) as string {
        switch($profile-name)
        case "sec"
        case "japan" return
            string-join(csv:serialize($res.Periods[], {serialize-null-as: ""}))
        default return ()
    }
}

let $results := api:serialize($result, $comment, $serializers, $format, "filings")
return api:check-and-return-results($token, $results, $format)
