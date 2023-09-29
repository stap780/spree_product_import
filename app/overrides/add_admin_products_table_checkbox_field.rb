Deface::Override.new(virtual_path: 'spree/admin/products/index',
    name: 'add_admin_products_table_header_checkbox_field',
    insert_after: "[data-hook='admin_products_index_headers']",
    partial: 'spree/admin/products/header_checkbox',
    original: 'eb9ecf7015fa51bb0adf7dafd7e6fdf1d652026d',
    disabled: false)

Deface::Override.new(virtual_path: 'spree/admin/products/index',
    name: 'add_admin_products_table_checkbox_fields',
    insert_after: "[data-hook='admin_products_index_rows']",
    partial: 'spree/admin/products/product_checkbox',
    original: 'eb9ecf7015fa51bb0adf7dafd7e6fdf1d652025d',
    disabled: false)


Deface::Override.new(virtual_path: 'spree/admin/products/index',
    name: 'add_admin_products_bulk_button',
    insert_after: "[id='admin_new_product']",
    partial: 'spree/admin/products/bulk_button',
    original: 'eb9ecf7015fa51bb0adf7dafd7e6fdf1d652025d',
    disabled: false)