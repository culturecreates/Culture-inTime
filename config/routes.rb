Rails.application.routes.draw do


  # utilities
  get 'queue/index', to: 'queue#index'
  get 'queue/clear', to: 'queue#clear'
  get 'queue/check_jobs', to: 'queue#check_jobs'

  # ajax
  get 'layout/add_field' , to: 'layout#add_field'  
  get 'layout/delete_field' , to: 'layout#delete_field' 
  get 'layout/move_up' , to: 'layout#move_up' 
  get 'layout/move_down' , to: 'layout#move_down' 

  scope "/:locale" do
    root to: 'home#index'
   
    get '/search', to: 'search#index'
    get '/search_rdf', to: 'search_rdf#index'

    #get '/productions/show', to: 'productions#show'
    
    resources :productions do 
      collection do 
        get 'show','derived'
      end
    end


    resources :spotlights do
      member do
        get 'stats', 'download'
      end
    end

    resources :data_sources do
      member do
        get  'load_rdf', 'apply_upper_ontology', 'load_secondary','fix_labels','convert_to_rdf_star'
      end
    end
  end

  root to: redirect("/#{I18n.default_locale}", status: 302), as: :redirected_root
  get "/*path", to: redirect("/#{I18n.default_locale}/%{path}", status: 302),
                constraints: { path: /(?!(#{I18n.available_locales.join("|")})\/).*/ },
                format: false
  
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
