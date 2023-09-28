if Gem.loaded_specs['spree_core'].version >= Gem::Version.create('3.5.0')
    Deface::Override.new(
      virtual_path: 'spree/admin/shared/sub_menu/_configuration',
      name: 'add_import_to_admin_sidebar',
      insert_bottom: '[data-hook="admin_configurations_sidebar_menu"]',
      text:     <<-HTML
      <%= configurations_sidebar_menu_item Spree.t('product_imports'), admin_product_imports_path if can? :admin, Spree::Config %>
     HTML
    )
  end