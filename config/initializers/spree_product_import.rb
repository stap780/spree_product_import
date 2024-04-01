Rails.application.config.after_initialize do

  Rails.application.config.spree_backend.main_menu.insert_after('products',
    Spree::Admin::MainMenu::SectionBuilder.new('ProductImports', 'inbox-fill.svg').
        with_admin_ability_check(Spree::Import).
        with_items([
         Spree::Admin::MainMenu::ItemBuilder.new('All', Spree::Core::Engine.routes.url_helpers.admin_imports_path).build
        ]).
        build
  )

end