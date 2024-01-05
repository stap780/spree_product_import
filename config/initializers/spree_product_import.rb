Rails.application.config.after_initialize do
    Rails.application.config.spree_backend.main_menu.add(
      Spree::Admin::MainMenu::SectionBuilder.new('ProductImports', 'inbox-fill.svg').
         with_admin_ability_check(Spree::ProductImport).
         with_items([
           Spree::Admin::MainMenu::ItemBuilder.new('AllImports', Spree::Core::Engine.routes.url_helpers.admin_product_imports_path).build
         ]).
         build
    )
end