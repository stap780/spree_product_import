class RenameTableProductImportsToImports < ActiveRecord::Migration[7.1]
  def change
    rename_table :spree_product_imports, :spree_imports
  end
end
