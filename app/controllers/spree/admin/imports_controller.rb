module Spree
  module Admin
    class ImportsController < ResourceController
      helper Spree::BaseHelper
      include Rails.application.routes.url_helpers

      before_action :load_data
      before_action :validate_params, only: [:update]

      def index
        params[:q] ||= {}
        @q = Spree::Import.ransack(params[:q])
        @q.sorts = "id desc" if @q.sorts.empty?
        @imports = @q.result.page(params[:page]).per(params[:per_page])
        # @imports = Spree::Import.all.page(params[:page] || 1).per(10)
      end
 
      #only file import action
      def new 
        @import = Spree::Import.new
      end

      def edit
        puts "edit ======="
        if @import.import_columns.size < 1
          service = ImportService::Import.new(@import)
          header_data = service.collect_file_header
          if header_data
            data = header_data.map{|d|{column_file: d, column_system: nil}}
            @import.import_columns.create!(data)
          else
            flash[:alert] = 'Import file not valid'
          end
        end
      end

      def create
        @import = Spree::Import.new(import_params)

        respond_to do |format|
          if @import.save
            puts "========="
            puts "SAVE"
            format.html { redirect_to spree.edit_admin_import_path(@import), notice: "import was successfully created." }
            format.json { render :show, status: :created, location: @product }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @import.errors, status: :unprocessable_entity }
          end
        end
      end

      def start #get
        # if @import.active
        service = ImportService::Import.new(@import)
        service.collect_data
        import = service.import
        if import
          respond_to do |format|
            format.html { redirect_to spree.admin_import_path, notice: "We start import process" }
            format.js do
                flash.now[:notice] = "We start import process"
            end
          end
        end
      # else
      #   respond_to do |format|
      #     format.js {
      #         render  :template => "/views/spree/admin/imports/import_start_error.js.erb"
      #     }
      #   end
      # end
      end

      def update
        success, message = validate_params
        puts "###########"
        puts "success"
        puts success
        puts "###########"
        if success
          respond_to do |format|
            if @import.update(import_params)
              format.html { redirect_to spree.admin_import_path, notice: "import was successfully updated." }
              format.json { render :show, status: :ok, location: @import }
            else
              format.html { render :edit, status: :unprocessable_entity }
              format.json { render json: @import.errors, status: :unprocessable_entity }
            end
          end
        else
          flash.now[:notice] = message
          render :edit, status: :unprocessable_entity 
        end
      end

      def destroy
        if @import.destroy
          flash[:success] = Spree.t('notice_messages.import_deleted')
        else
          flash[:error] = Spree.t('notice_messages.import_not_deleted', error: @import.errors.full_messages.to_sentence)
        end
        respond_with(@import) do |format|
          format.html { redirect_to collection_url }
          format.js { render_js_for_destroy }
        end
      end

      private

      def load_data
        @stores = Spree::Store.all
      end

      def import_params
        params.require(:import).permit(:active,:strategy, :title, :report, :import_file,:uniq_field, :update_title, :update_desc, :update_img, :update_quantity, :update_price, import_columns_attributes: [:id, :import_id, :column_file, :column_system, :_destroy])
      end

      def validate_params
        status = []
        message = []
        uniq_field = params[:import][:uniq_field]
        if params[:import][:strategy] == "product"
          puts "strategy: product // "
          message.push('strategy: product //')
          system = params[:import][:import_columns_attributes].values.map{|c| c['column_system']}.reject(&:blank?)
          puts "system => "+system.to_s
          status.push( system.include?(uniq_field) ? true : false )
          message.push( system.include?(uniq_field) ? '' : 'Need set uniq_field column' )
          status.push( system.include?('product#name') ? true : false )
          message.push( system.include?('product#name') ? '' : 'Need product name' )
          status.push( system.include?('product#price') ? true : false )
          message.push( system.include?('product#price') ? '' : 'Need set price' )
        end
        if params[:import][:strategy] == "product_variant"
          puts "strategy: product_variant // "
          message.push('strategy: product_variant //')
          system = params[:import][:import_columns_attributes].values.map{|c| c['column_system']}.reject(&:blank?)
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