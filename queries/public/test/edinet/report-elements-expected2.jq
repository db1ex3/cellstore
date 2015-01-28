import module namespace request = "http://www.28msec.com/modules/http-request";
import module namespace config = "http://apps.28.io/config";
[ {
    "Name" : "jppfs-cor:CurrentAssets",
    "Labels" : [ {
      "Role" : "http://www．xbrl．org/2003/role/totalLabel",
      "Language" : "ja",
      "Value" : "流動資産合計"
    }, {
      "Role" : "http://www．xbrl．org/2003/role/totalLabel",
      "Language" : "en",
      "Value" : "Total current assets"
    }, {
      "Role" : "http://www．xbrl．org/2003/role/verboseLabel",
      "Language" : "en",
      "Value" : "Current assets"
    }, {
      "Role" : "http://www．xbrl．org/2003/role/verboseLabel",
      "Language" : "ja",
      "Value" : "流動資産"
    }, {
      "Role" : "http://disclosure．edinet-fsa．go．jp/jppfs/ivt/role/totalLabel",
      "Language" : "en",
      "Value" : "Total current assets"
    }, {
      "Role" : "http://disclosure．edinet-fsa．go．jp/jppfs/ivt/role/totalLabel",
      "Language" : "ja",
      "Value" : "流動資産計"
    }, {
      "Role" : "http://disclosure．edinet-fsa．go．jp/jppfs/sec/role/totalLabel",
      "Language" : "ja",
      "Value" : "流動資産計"
    }, {
      "Role" : "http://disclosure．edinet-fsa．go．jp/jppfs/sec/role/totalLabel",
      "Language" : "en",
      "Value" : "Total current assets"
    }, {
      "Role" : "http://www．xbrl．org/2003/role/label",
      "Language" : "en",
      "Value" : "Current assets"
    }, {
      "Role" : "http://www．xbrl．org/2003/role/label",
      "Language" : "ja",
      "Value" : "流動資産"
    } ],
    "Facts" : "http://"||request:server-name()||":"||request:server-port()||"/v1/_queries/public/api/facts.jq?_method=POST&token="||$config:test-token||"&xbrl:Concept=jppfs-cor%3ACurrentAssets&aid=STANDARD-TAXONOMY-2014&format=&profile-name=japan&fiscalYear=ALL&fiscalPeriod=ALL&fiscalPeriodType=ALL",
    "ComponentRole" : "http://www.xbrl.org/2003/role/link",
    "ComponentLabel" : "Default Component",
    "Archive" : "STANDARD-TAXONOMY-2014"
  } ]
