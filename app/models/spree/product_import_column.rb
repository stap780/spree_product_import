module Spree
    class ProductImportColumn < Spree::Base
  
      validates :product_import_id, presence: true
      belongs_to :product_import

    
    end
end