module Spree
    module Admin
      class ProductImportsController < ResourceController
        before_action :load_data
        before_action :set_product_import, only: %i[ index show edit update destroy ]
  
        def index
            @product_imports = ProductImport.all
        end
          
        # GET /incases/new
        def new
            @product_import = ProductImport.new
        end

        def import_setup #post
            service = ProductImportService::Import.new(params[:file])
        
            import_data = service.collect_data
            #puts 'incase_import_data => '+incase_import_data.to_s
            if import_data
              @header = import_data[:header]
              @file_data = import_data[:file_data]
              @our_fields = Incase.import_attributes
              render 'import_setup'
            else
              flash[:alert] = 'Ошибка в файле импорта'
            end
        end
        
        def convert_file_data
            puts "start convert_file_data"
            @data_group_by_unumber = ProductImportService::Import.convert_file_data(params)
            @virtual_incases = ProductImportService::Import.collect_virtual_incases(@data_group_by_unumber)
            render 'convert_file_data'
        end

        private
  
        def load_data
        #   @engines = Spree::Tracker.engines.keys.sort.map { |k| [k.humanize, k] }
          @stores = Spree::Store.all
        end

        def set_incase
            @product_import = ProductImport.find(params[:id])
        end
      
          # Only allow a list of trusted parameters through.
        def product_import_params
            params.require(:incase).permit(:active, :title, :report, :file, :store_id, product_import_columns_attributes: [:id, :product_import_id, :column_file, :column_system, :_destroy])
        end

      end
    end
  end