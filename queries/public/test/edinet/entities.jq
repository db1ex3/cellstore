import module namespace test = "http://apps.28.io/test";

declare variable $local:expected as object :=
{
  "all" : [ "http://disclosure.edinet-fsa.go.jp E01225-000",
           "http://disclosure.edinet-fsa.go.jp E01264-000",
           "http://disclosure.edinet-fsa.go.jp E02166-000",
           "http://disclosure.edinet-fsa.go.jp E02274-000",
           "http://disclosure.edinet-fsa.go.jp E02513-000",
           "http://disclosure.edinet-fsa.go.jp E02529-000",
           "http://disclosure.edinet-fsa.go.jp E04147-000",
           "http://disclosure.edinet-fsa.go.jp E04425-000",
           "http://disclosure.edinet-fsa.go.jp E04430-000",
           "http://info.edinet-fsa.go.jp E01225-000",
           "http://info.edinet-fsa.go.jp E01264-000",
           "http://info.edinet-fsa.go.jp E02166-000",
           "http://info.edinet-fsa.go.jp E02274-000",
           "http://info.edinet-fsa.go.jp E02513-000",
           "http://info.edinet-fsa.go.jp E02529-000",
           "http://info.edinet-fsa.go.jp E04147-000",
           "http://info.edinet-fsa.go.jp E04425-000",
           "http://info.edinet-fsa.go.jp E04430-000",
           "http://info.edinet-fsa.go.jp EDINET-000",
           "http://www.tse.or.jp/sicc 54010",
           "http://www.tse.or.jp/sicc 54110",
           "http://www.tse.or.jp/sicc 72670",
           "http://www.tse.or.jp/sicc 77510",
           "http://www.tse.or.jp/sicc 80310",
           "http://www.tse.or.jp/sicc 80580",
           "http://www.tse.or.jp/sicc 90200",
           "http://www.tse.or.jp/sicc 94320",
           "http://www.tse.or.jp/sicc 94330" ],
  "NIKKEI" : [
    "http://disclosure.edinet-fsa.go.jp E01225-000",
    "http://disclosure.edinet-fsa.go.jp E01264-000",
    "http://disclosure.edinet-fsa.go.jp E02166-000",
    "http://disclosure.edinet-fsa.go.jp E02274-000",
    "http://disclosure.edinet-fsa.go.jp E02513-000",
    "http://disclosure.edinet-fsa.go.jp E02529-000",
    "http://disclosure.edinet-fsa.go.jp E04147-000",
    "http://disclosure.edinet-fsa.go.jp E04425-000",
    "http://disclosure.edinet-fsa.go.jp E04430-000",
    "http://info.edinet-fsa.go.jp E01225-000",
    "http://info.edinet-fsa.go.jp E01264-000",
    "http://info.edinet-fsa.go.jp E02166-000",
    "http://info.edinet-fsa.go.jp E02274-000",
    "http://info.edinet-fsa.go.jp E02513-000",
    "http://info.edinet-fsa.go.jp E02529-000",
    "http://info.edinet-fsa.go.jp E04147-000",
    "http://info.edinet-fsa.go.jp E04425-000",
    "http://info.edinet-fsa.go.jp E04430-000",
    "http://www.tse.or.jp/sicc 54010",
    "http://www.tse.or.jp/sicc 54110",
    "http://www.tse.or.jp/sicc 72670",
    "http://www.tse.or.jp/sicc 77510",
    "http://www.tse.or.jp/sicc 80310",
    "http://www.tse.or.jp/sicc 80580",
    "http://www.tse.or.jp/sicc 90200",
    "http://www.tse.or.jp/sicc 94320",
    "http://www.tse.or.jp/sicc 94330"
  ]
};

test:check-all-success({
    all: test:invoke-and-assert-deep-equal(
      "entities",
      {},
      function($b as item*) as item* { [ $b.Entities[]._id ] },
      $local:expected.all
    ),
    nikkei: test:invoke-and-assert-deep-equal(
      "entities",
      {tag:"NIKKEI"},
      function($b as item*) as item* { [ $b.Entities[]._id ] },
      $local:expected.NIKKEI
    ),
    example-json: test:invoke-and-assert-deep-equal(
      "entities",
      {cik:"E01225"},
      function($b as item*) as item* { $b.Entities },
      test:get-expected-result("edinet/entities-expected1.jq")
    ),
    example-xml: test:invoke-and-assert-deep-equal(
      "entities",
      {cik:"E01225", format: "xml"},
      function($b as item*) as item* { document { $b/Entities } },
      test:get-expected-result-xml("edinet/entities-expected1-xml.jq"),
      { Format: "xml" }
    )
})
