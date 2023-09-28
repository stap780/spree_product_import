module Spree
    class ProductImport < Spree::Base
  
        validates :store, presence: true
    
        scope :active, -> { where(active: true) }
        has_many :product_import_columns
        belongs_to :store
    
        def self.import_attributes
            our_fields = []
            products = []
            variants = []
            Spree::Product.attribute_names.each do |fi| 
                # fi = 'company' if fi == 'company_id' # fi = 'strah' if fi == 'strah_id'
                products.push(fi) if fi != 'id' && fi != 'created_at' && fi != 'updated_at'
            end
            product_hash = Hash.new
            product_hash['product'] = products.reject(&:blank?)
            our_fields.push(product_hash)
            Spree::Variant.attribute_names.each do |fi|
                variants.push(fi) if fi != 'id' && fi != 'created_at' && fi != 'updated_at'
            end
            variant_hash = Hash.new
            variant_hash['variant'] = variants.reject(&:blank?)
            our_fields.push(variant_hash)
            #puts our_fields.to_s
            our_fields
        end


    end
end