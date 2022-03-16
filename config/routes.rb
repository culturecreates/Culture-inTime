Rails.application.routes.draw do
  
  root 'home#index'

  get '/:locale' => 'home#index'



  get '/admin', to: 'admin#index', as: 'admin'
  get '/admin/build_cache', to: 'admin#build_cache', as: 'admin_build_cache'
 

 

  scope "/:locale" do
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
  
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
