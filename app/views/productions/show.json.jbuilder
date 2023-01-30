json.uri @production.entity_uri
json.date @production.date_entity
json.description @production.description
json.frame @production.framed_graph
json.graph JSON.parse(@production.graph.to_jsonld)



