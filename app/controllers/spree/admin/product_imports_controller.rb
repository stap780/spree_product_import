module Spree
  module Admin
    class ProductImportsController < ResourceController
      include Rails.application.routes.url_helpers

      before_action :load_data
      before_action :set_product_import, only: %i[ index show edit update import_start destroy ]
      before_action :validate_params, only: [:update]

      def index
        @product_imports = collection
      end

      def index_all
          # @product_imports = Spree::ProductImport.all
          @product_imports = collection
      end
        
      # GET /incases/new
      def new #only file import action
          @product_import = Spree::ProductImport.new
      end

      # GET /product_imports/1/edit
      def edit
        if @product_import.product_import_columns.size < 1
          service = ProductImportService::Import.new(@product_import)
          header_data = service.collect_file_header
          if header_data
            data = header_data.map{|d|{column_file: d, column_system: nil}}
            @product_import.product_import_columns.create!(data)
          else
            flash[:alert] = 'Import file not valid'
          end
        end
      end

      # POST /products
      def create
        @product_import = ProductImport.new(product_import_params)

        respond_to do |format|
          if @product_import.save 
            format.html { redirect_to edit_admin_product_import_path(@product_import), notice: "product_import was successfully created." }
            # format.html { redirect_to import_setup_admin_product_imports_path, notice: "product_import was successfully created." }
            format.json { render :show, status: :created, location: @product }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @product_import.errors, status: :unprocessable_entity }
          end
        end
      end

      def import_start #get
        # if @product_import.active
        service = ProductImportService::Import.new(@product_import)
        service.collect_data
        import = service.import
        if import
          respond_to do |format|
            format.html { redirect_to admin_product_import_path, notice: "We start import process" }
            format.js do
                flash.now[:notice] = "We start import process"
            end
          end
        end
      # else
      #   respond_to do |format|
      #     format.js {
      #         render  :template => "/views/spree/admin/product_imports/import_start_error.js.erb"
      #     }
      #   end
      # end
      end
      
      # def convert_file_data
      #   puts "start convert_file_data"
      #   @data_group_uniq_field = ProductImportService::Import.convert_file_data(params)
      #   @virtual_products = ProductImportService::Import.collect_virtual_incases(@data_group_uniq_field)
      #   render 'convert_file_data'
      # end


      # PATCH/PUT /products/1
      def update
        success, message = validate_params
        puts "###########"
        puts "success"
        puts success
        puts "###########"
        if success
          respond_to do |format|
            if @product_import.update(product_import_params)
              format.html { redirect_to admin_product_import_path, notice: "product_import was successfully updated." }
              format.json { render :show, status: :ok, location: @product_import }
            else
              format.html { render :edit, status: :unprocessable_entity }
              format.json { render json: @product_import.errors, status: :unprocessable_entity }
            end
          end
        else
          flash.now[:notice] = message
          render :edit, status: :unprocessable_entity 
        end
      end

      # DELETE /products/1
      def destroy
        if @product_import.destroy
          flash[:success] = Spree.t('notice_messages.product_import_deleted')
        else
          flash[:error] = Spree.t('notice_messages.product_import_not_deleted', error: @product_import.errors.full_messages.to_sentence)
        end
        respond_with(@product_import) do |format|
          format.html { redirect_to collection_url }
          format.js { render_js_for_destroy }
        end
      end

      private

      def load_data
        #   @engines = Spree::Tracker.engines.keys.sort.map { |k| [k.humanize, k] }
        @stores = Spree::Store.all
      end

      def set_product_import
          @product_import = Spree::ProductImport.find(params[:id])
      end

      def collection
        params[:q] ||= {}
        @search = Spree::ProductImport.ransack(params[:q])
        @collection = @search.result.page(params[:page]).per(params[:per_page])
      end
    
        # Only allow a list of trusted parameters through.
      def product_import_params
          params.require(:product_import).permit(:active,:strategy, :title, :report, :import_file,:uniq_field, :update_title, :update_desc, :update_img, :update_quantity, :update_price, product_import_columns_attributes: [:id, :product_import_id, :column_file, :column_system, :_destroy])
      end

      def validate_params
        status = []
        message = []
        uniq_field = params[:product_import][:uniq_field]
        if params[:product_import][:strategy] == "product"
          puts "strategy: product // "
          message.push('strategy: product //')
          system = params[:product_import][:product_import_columns_attributes].values.map{|c| c['column_system']}.reject(&:blank?)
          puts "system => "+system.to_s
          status.push( system.include?(uniq_field) ? true : false )
          message.push( system.include?(uniq_field) ? '' : 'Need set uniq_field column' )
          status.push( system.include?('product#name') ? true : false )
          message.push( system.include?('product#name') ? '' : 'Need product name' )
          status.push( system.include?('product#price') ? true : false )
          message.push( system.include?('product#price') ? '' : 'Need set price' )
        end
        if params[:product_import][:strategy] == "product_variant"
          puts "strategy: product_variant // "
          message.push('strategy: product_variant //')
          system = params[:product_import][:product_import_columns_attributes].values.map{|c| c['column_system']}.reject(&:blank?)
          puts "system product_variant => "+system.to_s
          status.push( system.include?(uniq_field) ? true : false )
          message.push( system.include?(uniq_field) ? '' : 'Need set uniq_field column' )
          status.push( system.include?('product#name') ? true : false )
          message.push( system.include?('product#name') ? '' : 'Need set product name' )
          status.push( system.include?('variant#price') ? true : false )
          message.push( system.include?('variant#price') ? '' : 'Need set variant price' )
        end
        check_status = status.uniq.to_s == "[true]" ? true : false
        [check_status, message.join(' ')]
      end

    end
  end
end