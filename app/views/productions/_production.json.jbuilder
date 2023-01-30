json.extract! production, :production_uri, :id, :label, :location_label, :location_uri, :date_entity, :production_company_uri, :production_company_label, :description, :main_image, :locality, :country
json.url production_url(production, format: :json)
