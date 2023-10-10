module Spree
    class ProductImport < Spree::Base
        has_one_attached :import_file, dependent: :destroy
        scope :active, -> { where(active: true) }
        has_many :product_import_columns, dependent: :destroy
        accepts_nested_attributes_for :product_import_columns, allow_destroy: true

        validate :import_file_size
    
        def self.import_attributes
            our_fields = Hash.new
            not_use_product_attr = ["id","available_on","deleted_at","slug","tax_category_id","shipping_category_id","created_at","updated_at", 
                                    "promotionable", "discontinue_on","public_metadata","private_metadata","status","make_active_at",
                                    "unique_identifier","unique_identifier_type","feed_active","preferences"]
            not_use_variant_attr = ["weight","height","width","depth","deleted_at","is_master","product_id","position",
                                    "track_inventory","tax_category_id","updated_at","discontinue_on","created_at","public_metadata",
                                    "private_metadata","unique_identifier","unique_identifier_type","show_in_product_feed","preferences"]
                           
            not_use_taxonomy_attr = ["id", "created_at", "updated_at", "position", "store_id", "public_metadata", "private_metadata", "preferences"]
            
            variants = Spree::Variant.attribute_names.map{|fi| [fi,'variant#'+fi] if !not_use_variant_attr.include?(fi)}+[['sku','variant#sku'],['price','variant#price'],['quantity','variant#quantity'],['images','variant#images']]

            products = Spree::Product.attribute_names.map{|fi| [fi,'product#'+fi] if !not_use_product_attr.include?(fi)}+[['sku','product#sku'],['price','product#price'],['cat1','product#cat1'],['cat2','product#cat2'],['cat3','product#cat3'],['quantity','product#quantity'],['images','product#images']]
            our_fields['product'] = products.reject(&:blank?)
            our_fields['variant'] = variants.reject(&:blank?)

            option_types = Spree::OptionType.all.map{|ot| [ot.presentation, 'option_type#'+ot.presentation]}
            our_fields['option_types'] = option_types.reject(&:blank?)

            properties = Spree::Property.all.map{|ot| [ot.presentation, 'property#'+ot.presentation]}
            our_fields['properties'] = properties.reject(&:blank?)
            
            # collections = Spree::Taxonomy.attribute_names.map{|fi| [fi,'taxonomy#'+fi]  if !not_use_variant_attr.include?(fi)}
            # our_fields['taxonomy'] = collections.reject(&:blank?)

            #puts our_fields.to_s
            our_fields
        end

        def import_file_size
            return unless import_file.attached?
          
            unless import_file.blob.byte_size <= 50.megabyte
              errors.add(:import_file, "is too big")
            end
          
            acceptable_types = ["text/csv"]
            unless acceptable_types.include?(import_file.content_type)
              errors.add(:import_file, "must be a CSV or XLS")
            end
        end


    end
end