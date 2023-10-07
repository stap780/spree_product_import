class CreateSpreeProductImports < SpreeExtension::Migration[7.0]
    def change
        create_table :spree_product_imports do |t|

          t.boolean :active, default: true, index: true
          t.string :title
          t.string :report
          t.string :file
          t.string :strategy
          t.string :uniq_field
          t.boolean :update_title, default: true, index: true
          t.boolean :update_desc, default: true, index: true
          t.boolean :update_img, default: true, index: true
          t.boolean :update_quantity, default: true, index: true
          t.boolean :update_price, default: true, index: true

          t.timestamps
          
        end
    end
end