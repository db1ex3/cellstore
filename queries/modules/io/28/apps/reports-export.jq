jsoniq version "1.0";
module namespace export = "http://apps.28.io/reports-export";

import module namespace random = "http://zorba.io/modules/random";

declare %an:sequential function export:cleanup($report as item) as item*
{
    (: add Ids everywhere :)
    for $object in descendant-objects($report)
    where exists($object.Name) and not(exists($object.Id))
    return
      insert json { "Id": random:uuid() } into $object;;

    export:remove-ui-states($report)
};

declare %private function export:remove-ui-states($report as item) as item*
{
    typeswitch($report)
    case $object as object return {|
        for $key in keys($object)
        return
            switch($key)
            case "Trees"
            case "To" return { $key : [ 
                (
                    if($object.$key instance of array)
                    then $object.$key[]
                    else values($object.$key)
                ) ! (export:remove-ui-states($$)) ] }
            case "children" return ()
            case "expanded" return ()
            case "$$hashKey" return ()
            default return { $key : export:remove-ui-states($object.$key) }
    |}
    case $array as array return [ ($array[]) ! (export:remove-ui-states($$)) ]
    default return $report
};
