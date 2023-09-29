module Spree
    module Admin
        module ProductImportsHelper

            def get_selected_value(of)
                selected_value = 'Название товара или услуги' if of == 'name'
                selected_value = 'Полное описание' if of == 'description'
                selected_value
            end

        end
    end
end
