Spree::Core::Engine.add_routes do
  namespace :admin, path: Spree.admin_path do
    get 'product_imports', to: 'product_imports#index_all'
    resources :product_imports do
      collection do
        # get :file_import  - because we have new action
        post :import_setup
        post :convert_file_data
      end
    end
    resources :product_import_columns
  end
end
