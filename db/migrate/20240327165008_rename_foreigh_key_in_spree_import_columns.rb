class RenameForeighKeyInSpreeImportColumns < ActiveRecord::Migration[7.1]
  def change
    rename_column :spree_import_columns, :product_import_id, :import_id
  end
end
