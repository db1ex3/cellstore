jsoniq version "1.0";

module namespace companies2 = "http://xbrl.io/modules/bizql/profiles/sec/companies2";

import module namespace companies = "http://xbrl.io/modules/bizql/profiles/sec/companies";

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
declare function companies2:companies(
    $ciks as string*,
    $tags as string*,
    $tickers as string*,
    $sics as string*) as object*
{
    if ($tags = "ALL")
    then companies:companies()
    else
        for $c in (
            companies:companies($ciks),
            companies:companies-for-tags($tags),
            companies:companies-for-tickers($tickers),
            companies:companies-for-SIC($sics)
        )
        group by $c._id
        return $c[1]
};