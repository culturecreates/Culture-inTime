require 'test_helper'

class DataSourceTest < ActiveSupport::TestCase
  setup do
    @source = data_sources(:one)
  end

  test "sparql_minus_unchanged_entities" do
    expected = "SELECT ?uri WHERE { ?a ?b ?c MINUS { ?uri a <http://schema.org/Event> . }} LIMIT 10"
    assert_equal  expected, @source.sparql_minus_unchanged_entities
  end

  test "sparql_with_cache_date" do
    @source = data_sources(:two)
    expected = "SELECT DISTINCT ?uri WHERE { ?uri schema:modifiedDate \"2021-04-08T21:04:12+00:00\"^^<http://www.w3.org/2001/XMLSchema#dateTime> }"
    assert_equal  expected, @source.sparql_with_cache_date
  end



end
