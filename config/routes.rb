Rails.application.routes.draw do

  scope "/:locale" do
    root to: 'home#index'
   
    get '/search', to: 'search#index'
    get '/search_rdf', to: 'search_rdf#index'
    get '/search_rdf/spotlight', to: 'search_rdf#spotlight'
    get '/search_rdf/data_source', to: 'search_rdf#data_source'

    get '/productions/show', to: 'productions#show'
    
    resources :productions
    resources :spotlights

    resources :data_sources do
      member do
        get  'load_rdf', 'apply_upper_ontology'
      end
    end
  end

  root to: redirect("/#{I18n.default_locale}", status: 302), as: :redirected_root
  get "/*path", to: redirect("/#{I18n.default_locale}/%{path}", status: 302),
                constraints: { path: /(?!(#{I18n.available_locales.join("|")})\/).*/ },
                format: false
  
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
