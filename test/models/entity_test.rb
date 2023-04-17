require 'test_helper'

class EntityTest < ActiveSupport::TestCase
  test "framing" do
    entity = Entity.new
    entity.entity_uri = "http://www.wikidata.org/entity/Q110835489"
    entity.graph
    expected = 22
    assert_equal  expected, entity.spotlight_properties.count
  end
end