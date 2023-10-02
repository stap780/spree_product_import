class AddColimnsToSpreeProductImports < SpreeExtension::Migration[7.0]
    def change
      add_column :spree_product_imports, :uniq_field, :string
      add_column :spree_product_imports, :update_title, :boolean
      add_column :spree_product_imports, :update_desc, :boolean
      add_column :spree_product_imports, :update_img, :boolean
      add_column :spree_product_imports, :update_quantity, :boolean
      add_column :spree_product_imports, :update_price, :boolean

    end
end