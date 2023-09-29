module Spree
  module Admin
    module ProductsControllerDecorator
      def bulk_delete
        if params[:product_ids]
          params[:product_ids].each do |id|
              product = product_scope.friendly.find(params[:id])
              product.destroy
          end
          flash[:success] = Spree.t('notice_messages.product_deleted')
        else
          alert = 'Choose product'
          flash[:error] = alert
          redirect_to collection_url
        end

      end
    end
  end
end
  
Spree::Admin::ProductsController.prepend(Spree::Admin::ProductsControllerDecorator)
