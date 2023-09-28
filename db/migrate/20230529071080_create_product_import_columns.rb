class CreateProductImportColumns < SpreeExtension::Migration[7.0]
    def change
        create_table :product_import_columns do |t|
            t.integer :product_import_id
            t.string :column_file
            t.string :column_system
            t.timestamps 
        end
    end
end