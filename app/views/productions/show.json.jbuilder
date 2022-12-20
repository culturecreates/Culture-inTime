json.uri @production.entity_uri
json.date @production.date_of_first_performance
json.description @production.description
json.graph JSON.parse(@production.graph.to_jsonld)


