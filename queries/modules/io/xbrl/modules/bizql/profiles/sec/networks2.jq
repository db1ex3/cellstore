jsoniq version "1.0";

module namespace sec-networks2 = "http://xbrl.io/modules/bizql/profiles/sec/networks2";

import module namespace archives = "http://xbrl.io/modules/bizql/archives";
import module namespace networks = "http://xbrl.io/modules/bizql/networks";
import module namespace components = "http://xbrl.io/modules/bizql/components";
import module namespace components2 = "http://xbrl.io/modules/bizql/components2";
import module namespace hypercubes = "http://xbrl.io/modules/bizql/hypercubes";

import module namespace sec-networks = "http://xbrl.io/modules/bizql/profiles/sec/networks";

(:~
 : <p>Retrieves the components with the given CID, or belonging to the given archives and corresponding to one of report
 : elements, concepts, disclosures, roles or label search.</p>
 :
 : @param $archives-or-aids a sequence of archives or AIDs.
 : @param $components-or-ids a sequence of components or their CIDs.
 : @param $report-elements a sequence of report element names.
 : @param $concepts a sequence of concept names.
 : @param $disclosures a sequence of disclosures.
 : @param $roles a sequence of role URIs.
 : @param $search a sequence of label search strings.
 : 
 : @return a sequence of components.
 :)
declare function sec-networks2:components(
    $archives-or-aids as item*,
    $components-or-ids as item*,
    $report-elements as string*,
    $disclosures as string*,
    $roles as string*,
    $search as string*) as object*
{
    let $archives as object* := archives:archives($archives-or-aids)
    return(
        components:components($components-or-ids)[exists($components-or-ids)],
        if (exists(($report-elements, $disclosures, $roles, $search)))
        then (
                components2:components-for-archives-and-concepts($archives, $report-elements),
                sec-networks:networks-for-filings-and-disclosures($archives, $disclosures),
                components2:components-for-archives-and-roles($archives, $roles),
                sec-networks:networks-for-filings-and-label($archives, $search)
            )
        else components:components-for-archives($archives)
    )
};

(:~
 : <p>Builds a standard definition model out of the specified component.</p>
 : <p>The concepts will be put on the y axis according to the presentation network.</p>
 : <p>The other dimensions are put on the x axis, with one breakdown for each.</p>
 : <p>Explicit dimensions are organized according to the dimension hierarchy from the domain-member network.</p>
 : <p>Typed dimensions are organized according to the actual values.</p>
 :
 : <p>One of the non-default hypercubes will be arbitrarily chosen. If none is available, the default hypercube will be picked.</p>
 : <p>Auto slicing will be performed against the fact table
 : 
 : @param $component a component object.
 :
 : @return a definition model
 :)
declare function sec-networks2:standard-definition-models-for-components($components as object*) as object
{
    sec-networks2:standard-definition-models-for-components($components, ())
};


(:~
 : <p>Builds a standard definition model out of the specified component.</p>
 : <p>The concepts will be put on the y axis according to the presentation network.</p>
 : <p>The other dimensions are put on the x axis, with one breakdown for each.</p>
 : <p>Explicit dimensions are organized according to the dimension hierarchy from the domain-member network.</p>
 : <p>Typed dimensions are organized according to the actual values.</p>
 :
 : @param $component a component object.
 : @param $options <p>some optional parameters, including:</p>
 : <ul>
 :  <li>HypercubeName: a string specifying which hypercube to use. By default, one of the non-default hypercubes will be arbitrarily chosen. If none
 :  is available, the default hypercube will be picked.</li>
 :  <li>AutoSlice: a boolean specifying whether or not slicing should be done automatically, looking at the fact table. Deactivating auto slicing will
 :  lead to better performance, but a more verbose table. If AutoSlice is active, dimensions with only one value in the fact pool will become
 : global filters rather than breakdowns on the x axis.</li>
 :  <li>Slicers: an object with forced slicers.</li>
 : </ul>
 :
 : @error components2:HYPERCUBE-DOES-NOT-EXIST if the specified hypercube is not found.
 : @return a definition model
 :)
declare function sec-networks2:standard-definition-models-for-components($components as object*, $options as object?) as object
{
    for $component in $components
    let $implicit-table as object := hypercubes:hypercubes-for-components($component, "xbrl:DefaultHypercube")
    let $table as object := components2:select-table($component, $options)

    let $auto-slice as boolean := empty($options.AutoSlice) or $options.AutoSlice
    let $facts as object*:=
        if($auto-slice)
        then hypercubes:facts($table)
        else ()
    let $dimensions as string*:= keys($table.Aspects)
    let $values-by-dimension as object := {|
        for $d in $dimensions
        return { $d : [ distinct-values($facts.Aspects.$d) ] }
    |}
    let $auto-slice-dimensions as string* :=
        keys($values-by-dimension)[size($values-by-dimension.$$) eq 1 and not ($$ = ("xbrl:Period", "sec:FiscalYear",  "sec:FiscalPeriod") ) ]
    let $user-slice-dimensions as string* :=
        keys($options.Slicers)

    let $column-dimensions as string* := keys($values-by-dimension)[not $$ =
        ("xbrl:Concept", "xbrl:Period", "xbrl:Unit", "xbrl:Entity", "sec:Archive", $auto-slice-dimensions, $user-slice-dimensions)]
    
    let $x-breakdowns as object* := (
        sec-networks2:standard-period-breakdown()[not (($auto-slice-dimensions, $user-slice-dimensions) = "xbrl:Period")],
        for $d as string in $column-dimensions
        let $metadata as object? := descendant-objects($implicit-table)[$$.Name eq $d]
        return
            if($d = ("sec:Accepted", "sec:FiscalYear", "sec:FiscalPeriod"))
            then sec-networks2:standard-typed-dimension-breakdown(
                $d,
                $values-by-dimension.$d[])
            else sec-networks2:standard-explicit-dimension-breakdown(
                $d,
                $metadata.Label,
                keys($table.Aspects.$d.Domains),
                $component.Role),
        sec-networks2:standard-entity-breakdown()[not (($auto-slice-dimensions, $user-slice-dimensions) = "xbrl:Entity")]
    )

    let $lineitems as string* := sec-networks:line-items-report-elements($component).Name
    let $presentation-network as object? := networks:networks-for-components-and-short-names($component, "Presentation")
    let $roots as string* := keys($presentation-network.Trees)
    let $lineitems as string* := if(exists($lineitems)) then $lineitems else $roots
    let $y-breakdowns as object := sec-networks2:standard-concept-breakdown($lineitems, $component.Role)

    return {
        ModelKind: "DefinitionModel",
        Labels: [$component.Label],
        Parameters: {},
        Breakdowns: {
            "x" : [
                $x-breakdowns
            ],
            "y": [
                $y-breakdowns
            ]
        },
        TableFilters: {|
            for $d as string in distinct-values(($auto-slice-dimensions, $user-slice-dimensions))
            return if($d = $user-slice-dimensions)
                   then { $d : $options.Slicers.$d }
                   else { $d : $values-by-dimension.$d[] },
            if (not $auto-slice)
            then { "sec:Archive" : $component.Archive }
            else ()
        |}
    }
};

(:~
 : <p>Returns the standard period breakdown.</p>
 :
 : @return the period breakdown.
 :)
declare %private function sec-networks2:standard-period-breakdown() as object
{
    {
        BreakdownLabels: [ "Period breakdown" ],
        BreakdownTrees: [
            {
                Kind: "Rule",
                Abstract: true,
                Labels: [ "Period [Axis]" ],
                Children: [ {
                    Kind: "Aspect",
                    Aspect: "xbrl:Period"
                } ]
            }
        ]
    }
};

declare %private function sec-networks2:standard-typed-dimension-breakdown($dimension-name as string, $dimension-values as atomic*) as object
{
    {
        BreakdownLabels: [ $dimension-name || " breakdown" ],
        BreakdownTrees: [
            {
                Kind: "Rule",
                Labels: [ $dimension-name || " [Axis]" ],
                Children: [
                    for $value in $dimension-values
                    return {
                        Kind: "Rule",
                        Labels: [ $value ],
                        AspectRulesSet: { "" : { $dimension-name : $value } }
                    }
                ]
            }
        ]
    }
};

declare %private function sec-networks2:standard-explicit-dimension-breakdown(
    $dimension-name as string,
    $dimension-label as string,
    $domain-names as string*,
    $role as string) as object
{
    {
        BreakdownLabels: [ "Dimension Breakdown" ],
        BreakdownTrees: [
            {
                Kind: "Rule",
                Abstract: true,
                Labels: [ $dimension-label ],
                Children: [
                    for $domain as string in $domain-names
                    return {
                        Kind: "DimensionRelationship",
                        LinkRole: $role,
                        Dimension: $dimension-name,
                        RelationshipSource: $domain,
                        FormulaAxis: "descendant",
                        Generations: 0
                    }
                ]
            }
        ]
    }
};

declare %private function sec-networks2:standard-entity-breakdown() as object
{
    {
        BreakdownLabels: [ "Entity breakdown" ],
        BreakdownTrees: [
            {
                Kind: "Rule",
                Abstract: true,
                Labels: [ "Reporting Entity [Axis]" ],
                ConstraintSets: { "" : {} },
                Children: [ {
                    Kind: "Aspect",
                    Aspect: "xbrl:Entity"
                } ]
            }
        ]
    }
};

declare %private function sec-networks2:standard-concept-breakdown(
    $line-items-elements as string*,
    $role as string) as object
{
    {
        BreakdownLabels: [ "Breakdown on concepts" ],
        BreakdownTrees: [
            for $lineitems as string in $line-items-elements
            return {
                Kind: "ConceptRelationship",
                LinkName: "link:presentationLink",
                LinkRole: $role,
                ArcName: "link:presentationArc", 
                ArcRole: "http://www.xbrl.org/2003/arcrole/parent-child",
                RelationshipSource: $lineitems,
                FormulaAxis: "descendant",
                Generations: 0,
                RollUpAgainstCalculationNetwork: false
            }
        ]
    }
};
