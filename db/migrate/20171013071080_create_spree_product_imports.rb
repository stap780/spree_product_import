class CreateSpreeProductImports < SpreeExtension::Migration[7.0]
    def change
        create_table :spree_product_imports do |t|

          t.boolean :active, default: true, index: true
          t.string :title
          t.string :report
          t.string :file
          t.timestamps
          
        end
    end
end