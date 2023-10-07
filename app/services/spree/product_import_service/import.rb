module Spree
    class ProductImportService::Import
        require 'open-uri'

        attr_accessor :product_import, :columns, :header, :file_data, :import_data

        def initialize(product_import)
            puts "ProductImportService::Import initialize"
            @product_import = product_import
            @columns = @product_import.product_import_columns
            # file = Rails.application.routes.url_helpers.url_for(product_import.import_file)
            # file = ActiveStorage::Blob.service.path_for(product_import.import_file.key)
            file = ActiveStorage::Blob.service.send(:path_for, product_import.import_file.key)
            # original_filename = product_import.import_file.blob
            @content_type =  product_import.import_file.blob.content_type
            # @file = File.new(file)
            @file = ActiveStorage::Blob.service.send(:path_for, product_import.import_file.key)
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
            file_uniq_column = @columns.where(column_system: "product#"+@product_import.uniq_field)[0].column_file
            system_columns = @columns.where.not(column_system: [nil,''])

            product_columns = system_columns.select{|c| c.column_system.include?('product')}
            variant_columns = system_columns.select{|c| c.column_system.include?('variant')}
            option_type_columns = system_columns.select{|c| c.column_system.include?('option_type')}
            property_columns = system_columns.select{|c| c.column_system.include?('property')}

            @import_data[:file_data].each do |line|
                images_data = []
                quantity_data = []
                line_data = Hash.new
                properties_data = Hash.new
                option_type_data = Hash.new
                taxon_data = Hash.new
                product_columns.each do |pc|
                    key = pc.column_system.remove('product#')
                    value = line[pc.column_file]
                    line_data["#{key}"] = value if key != 'images' && key != 'quantity' && key != 'cat1' && key != 'cat2' && key != 'cat3' && key != file_uniq_column
                    images_data.push(value) if key == 'images'
                    quantity_data.push(value) if key == 'quantity'
                    taxon_data["#{key}"] = value if key == 'cat1' || key == 'cat2' || key == 'cat3'
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
                puts "@product_import.uniq_field => "+@product_import.uniq_field.to_s
                puts "line[file_uniq_column] => "+line[file_uniq_column].to_s
                puts "##########"

                if @product_import.strategy == 'product'
                    product = Spree::Product.where("#{@product_import.uniq_field}" => line[file_uniq_column] )
                    create_update_product(product,line_data,quantity_data,properties_data,taxon_data,images_data)
                end
                if @product_import.strategy == 'product_variant'
                    variant = file_uniq_column == 'variant_id' ? Spree::Variant.find(line[file_uniq_column].to_i) : 
                                                                    Spree::Variant.find_by_sku(line[file_uniq_column])
                    product = variant.product
                    create_update_variant(option_type_data,variant,product,line_data,quantity_data,properties_data,taxon_data,images_data)
                end
            end
        end

        def create_update_product(product,line_data,quantity_data,properties_data,taxon_data,images_data)
            if product.present?
                Spree::Product.update(line_data)
                product.stock_items.first.update(count_on_hand: quantity_data.join()) if quantity_data.present?
                create_product_property(product, properties_data) if properties_data.present?
                create_product_taxon(product, taxon_data) if taxon_data.present?
                create_image(product, images_data.join()) if images_data.present?
                product
            else
                line_data["shipping_category_id"] = 1
                line_data["store_ids"] = [1]
                new_product = Spree::Product.new(line_data)
                new_product.set_slug
                new_product.save
                new_product.stock_items.create(count_on_hand: quantity_data.join()) if quantity_data.present?
                create_product_property(new_product, properties_data) if properties_data.present?
                create_product_taxon(new_product, taxon_data) if taxon_data.present?
                create_image(new_product, images_data.join()) if images_data.present?
                new_product
            end
        end

        def create_update_variant(option_type_data,variant,product,line_data,quantity_data,properties_data,taxon_data,images_data)
            puts 'start create_update_variant '+Time.now.to_s
            if variant.present?
                create_update_product(product,line_data,quantity_data,properties_data,taxon_data,images_data)
                variant.update(price: line_data['price']) if line_data['price'].present?
                variant.stock_items.first.update(count_on_hand: quantity_data.join()) if quantity_data.present?
            else
                get_product = product.present? ? product : create_update_product(product,line_data,quantity_data,properties_data,taxon_data,images_data)
                option_value_ids = []
                option_type_data.each do |key, value|
                    ov = Spree::OptionValue.find_or_create_by(name: value, presentation: value)
                    option_value_ids.push(ov.id)
                end
                get_product.variants.create(option_value_ids: option_value_ids, price: line_data['price'] ||= 0, sku: line_data['sku'] ||= '')
            end
		    puts 'finish create_update_variant '+Time.now.to_s
        end

        def create_image(object, images_data)
            puts 'start create_image '+Time.now.to_s
            images_data.split(' ').each do |image_url|
                clear_url = image_url.squish if image_url.respond_to?("squish")
                # url = URI.encode(clear_url)
                # file = URI.parse(url).open
                filename = File.basename(URI.parse(clear_url).path)
                file = URI.open(clear_url)
                image = Spree::Image.create!(attachment: { io: file, filename: filename })
                object.images << image
            end
		    puts 'finish create_image '+Time.now.to_s  
        end

        def create_product_property(product, properties_data)
            puts 'start create_product_property '+Time.now.to_s
            properties_data.each do |key, value|
                product_proper = Spree::ProductProperty.create!(property_name: key, value: value)
                product.product_properties << product_proper
            end
		    puts 'finish create_product_property '+Time.now.to_s
        end

        def create_product_taxon(product, taxon_data)
            puts 'start create_product_property '+Time.now.to_s
            taxonomy = Spree::Taxonomy.all.present? ? Spree::Taxonomy.first : 
                        Spree::Taxonomy.create(name: 'From Import', store_id: Spree::Store.default.id)
            taxon_data.each do |key, value|
                if key == cat1
                    taxon1 = Spree::Taxon.where(name: value).present? ? Spree::Taxon.where(name: value) : 
                            Spree::Taxon.create(name: value, taxonomy: taxonomy, parent: taxonomy.root)  
                end
                if key == cat2
                    taxon2 = Spree::Taxon.where(name: value).present? ? Spree::Taxon.where(name: value) : 
                            Spree::Taxon.create(name: value, taxonomy: taxonomy, parent: taxon1)  
                end
                if key == cat3
                    taxon3 = Spree::Taxon.where(name: value).present? ? Spree::Taxon.where(name: value) : 
                            Spree::Taxon.create(name: value, taxonomy: taxonomy, parent: taxon2)  
                end
                product.taxons << taxon1 if taxon1.present?
                product.taxons << taxon2 if taxon2.present?
                product.taxons << taxon3 if taxon3.present?
            end
		    puts 'finish create_product_property '+Time.now.to_s
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


# CSV.parse(product_import.import_file.download, headers: true, col_sep: ',', encoding: "UTF-8") do |row|
#  puts row
# end