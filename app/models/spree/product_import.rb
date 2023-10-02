module Spree
    class ProductImport < Spree::Base
  
        validates :store, presence: true
    
        scope :active, -> { where(active: true) }
        has_many :product_import_columns, dependent: :destroy
        accepts_nested_attributes_for :product_import_columns, allow_destroy: true
        belongs_to :store
    
        def self.import_attributes
            our_fields = []
            not_use_product_attr = ["available_on","deleted_at","slug","tax_category_id","shipping_category_id","created_at","updated_at", 
                                    "promotionable", "discontinue_on","public_metadata","private_metadata","status","make_active_at",
                                    "unique_identifier","unique_identifier_type","feed_active","preferences"]
            not_use_variant_attr = ["id","weight","height","width","depth","deleted_at","is_master","product_id","position",
                                    "track_inventory","tax_category_id","updated_at","discontinue_on","created_at","public_metadata",
                                    "private_metadata","unique_identifier","unique_identifier_type","show_in_product_feed","preferences"]
            not_use_taxonomy_attr = ["id", "created_at", "updated_at", "position", "store_id", "public_metadata", "private_metadata", "preferences"]
            
            products = Spree::Product.attribute_names.map{|fi| fi if !not_use_product_attr.include?(fi)}+['cat1','cat2','cat3','quantity','images']
            product_hash = Hash.new
            product_hash['product'] = products.reject(&:blank?)
            our_fields.push(product_hash)

            option_types = Spree::OptionType.all.map{|ot| ot.presentation}+['new']
            option_type_hash = Hash.new
            option_type_hash['option_type'] = option_types.reject(&:blank?)
            our_fields.push(option_type_hash)
            
            variants = Spree::Variant.attribute_names.map{|fi| fi if !not_use_variant_attr.include?(fi)}
            variant_hash = Hash.new
            variant_hash['variant'] = variants.reject(&:blank?)
            our_fields.push(variant_hash)

            collections = Spree::Taxonomy.attribute_names.map{|fi| fi if !not_use_variant_attr.include?(fi)}
            collection_hash = Hash.new
            collection_hash['taxonomy'] = collections.reject(&:blank?)

            #puts our_fields.to_s
            our_fields
        end


    end
end