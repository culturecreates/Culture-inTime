json.uri @production.entity_uri
json.date @production.date_entity
json.description @production.description
json.framed_graph @production.framed_graph
json.original_graph JSON.parse(@production.graph.dump(:jsonld))



