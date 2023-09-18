require 'test_helper'

class DataSourceTest < ActiveSupport::TestCase
  setup do
    @source = data_sources(:one)
  end

  test "add minus node" do
    expected = "SELECT ?uri WHERE { ?a ?b ?c MINUS { ?uri a <http://schema.org/Event> . ?feed schema:about ?uri ; schema:dateModified ?mod . filter(?mod <= \"2021-04-08T21:00:00+00:00\"^^xsd:dateTime) }} LIMIT 10"
    assert_equal  expected, @source.sparql_minus_unchanged_entities
  end



end
