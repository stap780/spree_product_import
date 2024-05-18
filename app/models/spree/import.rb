module Spree
    class Import < Spree::Base
        has_one_attached :import_file
        scope :active, -> { where(active: true) }
        has_many :import_columns, dependent: :destroy
        accepts_nested_attributes_for :import_columns, allow_destroy: true

        validate :import_file_size

        OPTION_TYPE_ARRAY = Spree::OptionType.count > 0 ? Spree::OptionType.all.map{|ot| [ot.presentation, 'option_type#'+ot.presentation] if ot.presentation.present? } : []
        PROPERTY_ARRAY = Spree::Property.count > 0 ? Spree::Property.all.map{|ot| [ot.presentation, 'property#'+ot.presentation] if ot.presentation.present? } : []
    
        def self.import_attributes
            our_fields = Hash.new
            not_use_product_attr = ["id","available_on","deleted_at","slug","tax_category_id","shipping_category_id","created_at","updated_at", 
                                    "promotionable", "discontinue_on","public_metadata","private_metadata","status","make_active_at",
                                    "unique_identifier","unique_identifier_type","feed_active","preferences"]
            not_use_variant_attr = ["deleted_at","is_master","product_id","position",
                                    "track_inventory","tax_category_id","updated_at","discontinue_on","created_at","public_metadata",
                                    "private_metadata","unique_identifier","unique_identifier_type","show_in_product_feed","preferences"]
                           
            not_use_taxonomy_attr = ["id", "created_at", "updated_at", "position", "store_id", "public_metadata", "private_metadata", "preferences"]
            
            variants = Spree::Variant.attribute_names.map{|fi| [fi,'variant#'+fi] if !not_use_variant_attr.include?(fi)}+[['price','variant#price'],['quantity','variant#quantity'],['images','variant#images']]

            products = Spree::Product.attribute_names.map{|fi| [fi,'product#'+fi] if !not_use_product_attr.include?(fi)}+[['barcode','product#barcode'],['sku','product#sku'],['price','product#price'],['cat1','product#cat1'],['cat2','product#cat2'],['cat3','product#cat3'],['quantity','product#quantity'],['images','product#images'],['weight','product#weight'],['height','product#height'],['width','product#width'],['depth','product#depth']]
            our_fields['product'] = products.reject(&:blank?)
            our_fields['variant'] = variants.reject(&:blank?)

            option_types = Spree::Import::OPTION_TYPE_ARRAY
            our_fields['option_types'] = option_types.reject(&:blank?)

            properties = Spree::Import::PROPERTY_ARRAY
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

        def self.ransackable_attributes(auth_object = nil)
          Spree::Import.attribute_names
          #[:active,:strategy, :title, :report, :import_file,:uniq_field, :update_title, :update_desc, :update_img, :update_quantity, :update_price]
        end

    end
end