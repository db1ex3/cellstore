import module namespace response = "http://www.28msec.com/modules/http-response";
import module namespace test = "http://apps.28.io/test";

declare %an:nondeterministic function local:test-map($expected as integer, $params as object) as item
{
    let $endpoint := "concept-map"
    let $request := test:invoke($endpoint, $params)
    let $actual as integer := count($request[2].Trees[])
    let $status as integer := $request[1]
    return test:assert-eq($expected, $actual, $status, test:url($endpoint, $params))
};


declare %an:sequential function local:check($o as object) as object
{
    if (not(every $k in (keys($o) ! $o.$$) satisfies ($k instance of boolean and $k)))
    then {
            response:status-code(500);
            $o
    } else
            $o
};

local:check({
    all: true (: disabling for now until we have the reports module checked in local:test-map(1, "&name=FundamentalAccountingConcepts"):)
})
