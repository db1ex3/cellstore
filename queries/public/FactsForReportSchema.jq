
import module namespace report-schemas = "http://xbrl.io/modules/bizql/report-schemas";
import module namespace sec = "http://xbrl.io/modules/bizql/profiles/sec/core";
import module namespace companies = "http://xbrl.io/modules/bizql/profiles/sec/companies";
import module namespace sec-fiscal = "http://xbrl.io/modules/bizql/profiles/sec/fiscal/core";
import module namespace entities = "http://xbrl.io/modules/bizql/entities";
import module namespace archives = "http://xbrl.io/modules/bizql/archives";
import module namespace response = "http://www.28msec.com/modules/http-response";
import module namespace request = "http://www.28msec.com/modules/http-request";
import module namespace session = "http://apps.28.io/session";


variable $cik := let $cik := request:param-values("cik","0000021344")
                 return if (empty($cik))
                            then error(QName("local:INVALID-REQUEST"), "cik: mandatory parameter not found")
                            else $cik;
variable $periodFocus := let $periodFocus := request:param-values("fiscalPeriodFocus","FY")
                         return if (empty($periodFocus))
                                then error(QName("local:INVALID-REQUEST"),"fiscalPeriodFocus: mandatory parameter not found")
                                else $periodFocus;
variable $yearFocus := let $yearFocus := request:param-values("fiscalYearFocus","2011") ! ($$ cast as integer)
                       return if (empty($yearFocus))
                                then error(QName("local:INVALID-REQUEST"), "fiscalYearFocus: mandatory parameter not found")
                                else $yearFocus ! ($$ cast as integer);

variable $entity := let $entity := entities:entities($cik ! companies:eid($$))
                    return if (empty($entity))
                           then  error(QName("local:INVALID-REQUEST"), "Given CIK:"||$cik|| " not found")
                           else  $entity;
                           
variable $reportSchema := let $reportSchema := request:param-values("reportSchema","FundamentalAccountingConcepts")
                          return if(empty($reportSchema))
                          then error(QName("local:INVALID-REQUEST"),"reportSchema: mandatory parameter not found") 
                          else $reportSchema;
                          
variable $schema := let $schema := report-schemas:report-schemas($reportSchema)
                    return if (empty($schema))
                    then  error(QName("local:INVALID-REQUEST"), "Given reportSchema:"||$schema|| " not found")
                    else $schema;
                    
variable $aid := request:param-values("aid");


for $archive in 
        (if (exists($entity))
        then
            for $e in $entity, $p in $periodFocus, $y in $yearFocus
            for $f in sec-fiscal:filings-for-entities-and-fiscal-periods-and-years($e, $p, $y)
            order by $f.Profiles.SEC.AcceptanceDatetime
            group by $e._id, $p, $y
            return $f[1]
        else (), archives:archives($aid))
let $format  := lower-case(substring-after(request:path(), ".jq.")) (: text, xml, or json (default) :) 
let $populatedSchema := sec:populate-schema-with-facts($schema, $archive)
return  if(session:only-dow30($entity) or session:valid())
        then [ $populatedSchema ]
        else {
            response:status-code(401);
            session:error("accessing filings of an entity that is not in the DOW30", $format)
        }
