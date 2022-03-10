require 'test_helper'

include ArtsdataAPI::V1

class ClientTest < ActionView::TestCase

  test "do execute_sparql" do
    expected = "Dara Ó Briain"
    client = ArtsdataApi::V1::Client.new()
    sparql = "PREFIX schema: <http://schema.org/> select ?name where { <http://kg.artsdata.ca/resource/K12-298> schema:name ?name }"
    assert_equal expected, client.execute_sparql(sparql).first['name']['value']
  end
  
end