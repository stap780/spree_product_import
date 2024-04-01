
Spree::Core::Engine.add_routes do
  namespace :admin, path: Spree.admin_path do
    resources :imports, except: [] do
      member do
        get :start
      end
      collection do
        post :import_setup
        post :convert_file_data
      end
    end
    resources :import_columns
  end
end