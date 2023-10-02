class CreateSpreeProductImports < SpreeExtension::Migration[7.0]
    def change
        create_table :spree_product_imports do |t|

          t.boolean :active, default: true, index: true
          t.string :title
          t.string :report
          t.string :file
          t.string :uniq_field
          t.boolean :update_title, default: true
          t.boolean :update_desc, default: true
          t.boolean :update_img, default: true
          t.boolean :update_quantity, default: true
          t.boolean :update_price, default: true
          t.timestamps
          
        end
    end
end