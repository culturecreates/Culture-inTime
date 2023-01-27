json.key_format! camelize: :lower
json.deep_format_keys!
json.array! @entities, partial: "search_rdf/resource", as: :resource