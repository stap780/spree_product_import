module Spree
    module Admin
        module ImportsHelper

            def get_selected_value(of)
                selected_value = 'Название товара или услуги' if of == 'name'
                selected_value = 'Полное описание' if of == 'description'
                selected_value
            end

            def file_link(object)
                Rails.application.routes.url_helpers.url_for(object)
            end

        end
    end
end
