class RenameTableProductImportColumnsToImportColumns < ActiveRecord::Migration[7.1]
  def change
    rename_table :spree_product_import_columns, :spree_import_columns
  end
end
