module Spree
    class ImportService::Import
        require 'open-uri'
        require "addressable/uri"

        attr_accessor :import, :columns, :header, :file_data, :import_data

        def initialize(import)
            puts "ProductImportService::Import initialize"
            @import = import
            @columns = @import.import_columns
            # file = Rails.application.routes.url_helpers.url_for(import.import_file)
            # file = ActiveStorage::Blob.service.path_for(import.import_file.key)
            file = ActiveStorage::Blob.service.send(:path_for, import.import_file.key)
            # original_filename = import.import_file.blob
            @content_type =  import.import_file.blob.content_type
            # @file = File.new(file)
            @file = ActiveStorage::Blob.service.send(:path_for, import.import_file.key)
            @header
            @file_data = []
            @import_data
        end

        def collect_file_header
            puts 'collect_file_header import file '+Time.now.to_s
            spreadsheet = open_spreadsheet(@file)
            header = spreadsheet.row(1)
            @header = header.present? ? header : false
        end
        
        def collect_data
            puts 'collect_data import file '+Time.now.to_s
            spreadsheet = open_spreadsheet(@file)
            header = spreadsheet.row(1)
            @header = header
            (2..spreadsheet.last_row).each do |i|
                row = Hash[[header, spreadsheet.row(i)].transpose]
                @file_data.push(row)
            end
            puts 'finish collect_data import file '+Time.now.to_s
            @import_data = @header.present? && @file_data.present? ? {header: @header, file_data: @file_data} : false
        end

        def import
            file_uniq_column = @columns.where(column_system: @import.uniq_field)[0].column_file
            system_columns = @columns.where.not(column_system: [nil,''])

            product_columns = system_columns.select{|c| c.column_system.include?('product')}
            variant_columns = system_columns.select{|c| c.column_system.include?('variant')}
            option_type_columns = system_columns.select{|c| c.column_system.include?('option_type')}
            property_columns = system_columns.select{|c| c.column_system.include?('property')}

            @import_data[:file_data].each do |line|
                images_data = []
                variant_images_data = []
                product_data = Hash.new
                variant_data = Hash.new
                properties_data = Hash.new
                option_type_data = Hash.new
                taxon_data = Hash.new
                product_columns.each do |pc|
                    key = pc.column_system.remove('product#')
                    value = line[pc.column_file]
                    product_data["#{key}"] = value if key != 'images' && key != 'cat1' && key != 'cat2' && key != 'cat3' && key != file_uniq_column
                    images_data.push(value) if key == 'images'
                    taxon_data["#{key}"] = value if key == 'cat1' || key == 'cat2' || key == 'cat3'
                end
                variant_columns.each do |pc|
                    key = pc.column_system.remove('variant#')
                    value = line[pc.column_file]
                    variant_data["#{key}"] = value if key != 'images' && key != file_uniq_column
                    variant_images_data.push(value) if key == 'images'
                end
                option_type_columns.each do |pc|
                    key = pc.column_system.remove('option_type#')
                    value = line[pc.column_file]
                    option_type_data["#{key}"] = value
                end
                property_columns.each do |pc|
                    key = pc.column_system.remove('property#')
                    value = line[pc.column_file]
                    properties_data["#{key}"] = value
                end

                puts "##########"
                puts "@import.uniq_field => "+@import.uniq_field.to_s
                puts "line[file_uniq_column] => "+line[file_uniq_column].to_s
                puts "file_uniq_column => "+file_uniq_column.to_s
                puts "##########"

                if @import.strategy == 'product'
                    product = Spree::Product.where("#{@import.uniq_field.remove('product#')}" => line[file_uniq_column] )
                    create_update_product(  product.take, 
                                            product_data,
                                            properties_data,
                                            taxon_data,
                                            images_data )
                end
                if @import.strategy == 'product_variant'
                    puts "##############"
                    puts "strategy = product_variant"
                    puts "##############"
                    variant = nil
                    variant = Spree::Variant.find(line[file_uniq_column].to_i) if @import.uniq_field == 'variant#id'
                    variant = Spree::Variant.find_by_sku(line[file_uniq_column]) if @import.uniq_field == 'variant#sku'
                    product = variant.present? ? variant.product : Spree::Product.where(name: line[file_uniq_column] ).take
                    create_update_variant(  option_type_data,
                                            variant,
                                            product,
                                            variant_data,
                                            product_data,
                                            properties_data,
                                            taxon_data,
                                            variant_images_data)
                end
            end
        end

        def create_update_product(product,product_data,properties_data,taxon_data,images_data)
            if product.present?
                pr_quantity = product_data['quantity']
                pr_price = product_data['price']
                product.update(product_data.except!('quantity').except!('price'))
                product.update(price: pr_price) if @import.update_price && pr_price.present?
                if @import.update_quantity && pr_quantity.present?
                    if product.stock_items.present?
                        product.stock_items.first.update(count_on_hand: pr_quantity)
                    else
                        product.stock_items.create(count_on_hand: pr_quantity, stock_location_id: Spree::StockLocation.first.id)
                    end
                end
                create_product_property(product, properties_data) if properties_data.present?
                create_taxon(taxon_data) if taxon_data.present?
                product_to_taxon(product, taxon_data) if taxon_data.present?
                create_image(product, images_data.join()) if @import.update_img && images_data.present?
                product
            else
                product_data["shipping_category_id"] = 1
                product_data["store_ids"] = [Spree::Store.first.id]
                pr_quantity = product_data['quantity']
                new_product = Spree::Product.new(product_data.except!('quantity'))
                new_product.set_slug
                new_product.save
                if @import.update_quantity && pr_quantity.present?
                    if new_product.stock_items.present?
                        new_product.stock_items.first.update(count_on_hand: pr_quantity)
                    else
                        new_product.stock_items.create(count_on_hand: pr_quantity, stock_location_id: Spree::StockLocation.first.id)
                    end
                end
                create_product_property(new_product, properties_data) if properties_data.present?
                create_taxon(taxon_data) if taxon_data.present?
                product_to_taxon(new_product, taxon_data) if taxon_data.present?
                create_image(new_product, images_data.join()) if @import.update_img && images_data.present?
                new_product
            end
        end

        def create_update_variant(option_type_data,variant,product,variant_data,product_data,properties_data,taxon_data,variant_images_data)
            puts 'start create_update_variant '+Time.now.to_s
            if variant.present?
                var_quantity = variant_data['quantity']
                create_update_product(product,product_data,properties_data,taxon_data,nil)
                variant.update(variant_data.except!('quantity')) if variant_data.present?
                variant.update(price: variant_data['price']) if @import.update_price && variant_data['price'].present?
                if @import.update_quantity && var_quantity.present?
                    if variant.stock_items.present?
                        variant.stock_items.first.update(count_on_hand: var_quantity)
                    else
                        variant.stock_items.create(count_on_hand: var_quantity, stock_location_id: Spree::StockLocation.first.id)
                    end
                end
                option_value_ids = collect_option_value_ids(option_type_data) if option_type_data.present?
                variant.update(option_value_ids: option_value_ids) if option_type_data.present?
                create_image(variant, variant_images_data.join()) if @import.update_img && variant_images_data.present?
            else
                get_product = product.present? ? product : create_update_product(product,product_data.merge!({"price" => variant_data["price"]}),properties_data,taxon_data,nil)
                option_value_ids = option_type_data.present? ? collect_option_value_ids(option_type_data) : []
                puts "Create variant option_value_ids => "+option_value_ids.to_s
                price = variant_data['price'] || 0
                sku = variant_data['sku'] || ''
                new_variant = get_product.variants.new(option_value_ids: option_value_ids, price: price, sku: sku)
                new_variant.save
                if @import.update_quantity && variant_data['quantity'].present?
                    if new_variant.stock_items.present?
                        new_variant.stock_items.first.update(count_on_hand: variant_data['quantity'])
                    else
                        new_variant.stock_items.create(count_on_hand: variant_data['quantity'], stock_location_id: Spree::StockLocation.first.id)
                    end
                end
                create_image(new_variant, variant_images_data.join()) if @import.update_img && variant_images_data.present?
            end
		    puts 'finish create_update_variant '+Time.now.to_s
        end

        def create_image(object, images_data)
            puts 'start create_image '+Time.now.to_s
            images_data.split(' ').each do |image_url|
                # clear_url = image_url.squish if image_url.respond_to?("squish")
                clear_url = Addressable::URI.parse(image_url).normalize
                # url = URI.encode(clear_url)
                # file = URI.parse(url).open
                # filename = File.basename(URI.parse(clear_url).path)
                filename = File.basename(image_url)
                file = URI.open(clear_url)
                image = Spree::Image.create!(attachment: { io: file, filename: filename })
                object.images << image
            end
		    puts 'finish create_image '+Time.now.to_s  
        end

        def create_product_property(product, properties_data)
            puts 'start create_product_property '+Time.now.to_s
            properties_data.each do |key, value|
                # product_proper =  Spree::ProductProperty.create!(property_name: key, value: value)
                # product.product_properties << product_proper
                property_name = key
                property_value = value
                product.set_property(property_name, property_value)
            end
		    puts 'finish create_product_property '+Time.now.to_s
        end

        def create_taxon(taxon_data)
            puts 'start create_taxon '+Time.now.to_s
            taxonomy = Spree::Taxonomy.find_by_name('From Import').present? ?  Spree::Taxonomy.find_by_name('From Import') : 
                        Spree::Taxonomy.create(name: 'From Import', store_id: Spree::Store.default.id)
            taxon_root_id = taxonomy.taxons.first.id
            if taxon_root_id.present? && !Spree::Taxon.where(name: taxon_data['cat1'], parent_id: taxon_root_id).present?
                taxon1 = taxonomy.taxons.create(name: taxon_data['cat1'], parent_id: taxon_root_id)
            end
            if taxon1.present? && !Spree::Taxon.where(name: taxon_data['cat2'], parent_id: taxon1.id).present?
                taxon2 = taxonomy.taxons.create(name: taxon_data['cat2'], parent_id: taxon1.id)
            end
            if taxon2.present? && !Spree::Taxon.where(name: taxon_data['cat3'], parent_id: taxon2.id).present?
                taxon3 = taxonomy.taxons.create(name: taxon_data['cat3'], parent_id: taxon2.id)
            end
        end

        def product_to_taxon(product, taxon_data)
            puts 'start create_product_taxon '+Time.now.to_s
            taxonomy = Spree::Taxonomy.find_by_name('From Import').present? ?  Spree::Taxonomy.find_by_name('From Import') : Spree::Taxonomy.first

            puts "taxon_data => "+taxon_data.to_s
            taxon_root_id = taxonomy.taxons.first.id
            puts "taxon_root_id =>"+taxon_root_id.to_s
            taxon1 = Spree::Taxon.where(name: taxon_data['cat1'], parent_id: taxon_root_id).take if Spree::Taxon.where(name: taxon_data['cat1'], parent_id: taxon_root_id).present?
            taxon2 = Spree::Taxon.where(name: taxon_data['cat2'], parent_id: taxon1.id).take if Spree::Taxon.where(name: taxon_data['cat2'], parent_id: taxon1.id).present?
            taxon3 = Spree::Taxon.where(name: taxon_data['cat3'], parent_id: taxon2.id).take if Spree::Taxon.where(name: taxon_data['cat3'], parent_id: taxon2.id).present?

            product.taxons << taxon1 if taxon1.present? && !product.taxon_ids.include?(taxon1.id)
            product.taxons << taxon2 if taxon2.present? && !product.taxon_ids.include?(taxon2.id)
            product.taxons << taxon3 if taxon3.present? && !product.taxon_ids.include?(taxon3.id)
            puts 'finish create_product_property '+Time.now.to_s
        end

        def collect_option_value_ids(option_type_data)
            option_value_ids = []
            puts "option_type_data =>"+option_type_data.to_s
            option_type_data.each do |key, value|
                # puts "key =>"+key.to_s
                # puts "value =>"+value.to_s
                option_type =  Spree::OptionType.find_by_name(key) || Spree::OptionType.find_by_presentation(key)
                check_ov = Spree::OptionValue.find_by_name(value)
                ov = check_ov.present? ? check_ov : Spree::OptionValue.create(name: value, presentation: value, option_type_id: option_type.id)
                # ov = Spree::OptionValue.find_or_create_by(name: value, presentation: value, option_type_id: option_type.id)
                option_value_ids.push(ov.id)
            end
            option_value_ids
        end

        def open_spreadsheet(file)
            if file.is_a? String
                if  @content_type == "text/csv"
                #   Roo::CSV.new(file, csv_options: {col_sep: ";", quote_char: "\x00"})
                  Roo::CSV.new(file,csv_options: {encoding: Encoding::UTF_8})
                else
                  Roo::Excelx.new(file, file_warning: :ignore)
                end
            else
                case File.extname(file.original_filename)
                when '.csv' then Roo::CSV.new(file.path,csv_options: {encoding: Encoding::UTF_8}) # csv_options: {col_sep: ";",encoding: "windows-1251:utf-8"})
                when '.xls' then Roo::Excel.new(file.path)
                when '.xlsx' then Roo::Excelx.new(file.path)
                when '.XLS' then Roo::Excel.new(file.path)
                else raise "Unknown file type: #{file.original_filename}"
                end
            end      
        end
        
    end
end


# CSV.parse(import.import_file.download, headers: true, col_sep: ',', encoding: "UTF-8") do |row|
#  puts row
# end