require 'test_helper'

class JobsHelperTest < ActionView::TestCase

  test "convertToStar" do
    expected = <<~RDF
    <http://www.wikidata.org/entity/Q123> <http://www.wikidata.org/prop/direct/P248> \"Hello, world!\" .
    <http://www.wikidata.org/entity/Q123> <http://www.wikidata.org/prop/P248> <http://www.wikidata.org/statement1> .
    <http://www.wikidata.org/statement1> <http://www.wikidata.org/prop/statement/P248> \"Hello, world!\" .
    <http://www.wikidata.org/statement1> <http://www.wikidata.org/prop/qualifier/P111> \"John\" .
    <<<http://www.wikidata.org/entity/Q123> <http://www.wikidata.org/prop/direct/P248> \"Hello, world!\">> <http://www.wikidata.org/prop/qualifier/P111> \"John\" .
    RDF

    graph = RDF::Graph.new << [RDF::URI("http://www.wikidata.org/entity/Q123"), RDF::URI("http://www.wikidata.org/prop/direct/P248"), "Hello, world!"]
    graph << [RDF::URI("http://www.wikidata.org/entity/Q123"), RDF::URI("http://www.wikidata.org/prop/P248"), RDF::URI("http://www.wikidata.org/statement1")]
    graph << [RDF::URI("http://www.wikidata.org/statement1"), RDF::URI("http://www.wikidata.org/prop/statement/P248"), "Hello, world!"]
    graph << [RDF::URI("http://www.wikidata.org/statement1"), RDF::URI("http://www.wikidata.org/prop/qualifier/P111"), "John"]
  
   assert_equal expected, convert_to_star(graph).dump(:ntriples)
  end


  
end