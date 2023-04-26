require 'test_helper'

class RDFGraphTest < ActionView::TestCase
  test "persist" do
    statement = RDF::Statement(RDF::URI('http://example.com/1'), RDF::URI('http://schema.org/name'), RDF::Literal('Gregory'))
    graph = RDF::Graph.new << [statement, RDF::URI("ex:certainty"), RDF::Literal(1)]
    turtle = graph.dump(:ttl, validate: false)  # graph.to_turtle also works
    graph_name = "http://tests.com"
    VCR.use_cassette('RDFGraphTest_persist') do
      # TODO VCR not working?
      RDFGraph.persist(turtle, graph_name)
    end
  end

  test "persist wikidata graph" do
    graph = RDF::Graph.load("http://www.wikidata.org/entity/Q47401546", rdfstar: true)
    
    expected = <<~RDF
    :a :name "Alice" {| :statedBy :bob ; :recorded "2021-07-07"^^xsd:date |} .
    RDF
    
    graph = ApplicationController.helpers.convert_to_star(graph)
    turtle = graph.dump(:ttl, validate: false)  # graph.to_turtle also works
    graph_name = "http://tests-wikidata.com"
    RDFGraph.persist(turtle, graph_name)
  end
 

end
