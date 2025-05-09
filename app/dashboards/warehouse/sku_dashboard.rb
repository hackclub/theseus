require "administrate/base_dashboard"

module Warehouse
  class SKUDashboard < Administrate::BaseDashboard
    # ATTRIBUTE_TYPES
    # a hash that describes the type of each of the model's fields.
    #
    # Each different type represents an Administrate::Field object,
    # which determines how the attribute is displayed
    # on pages throughout the dashboard.
    ATTRIBUTE_TYPES = {
      id: Field::Number,
      actual_cost_to_hc: Field::String.with_options(searchable: false),
      ai_enabled: Field::Boolean,
      average_po_cost: Field::String.with_options(searchable: false),
      category: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
      country_of_origin: Field::String,
      customs_description: Field::Text,
      declared_unit_cost_override: Field::String.with_options(searchable: false),
      description: Field::Text,
      enabled: Field::Boolean,
      hs_code: Field::String,
      in_stock: Field::Number,
      inbound: Field::Number,
      name: Field::String,
      sku: Field::String,
      zenventory_id: Field::String,
      created_at: Field::DateTime,
      updated_at: Field::DateTime,
    }.freeze

    # COLLECTION_ATTRIBUTES
    # an array of attributes that will be displayed on the model's index page.
    #
    # By default, it's limited to four items to reduce clutter on index pages.
    # Feel free to add, remove, or rearrange items.
    COLLECTION_ATTRIBUTES = %i[
      sku
      name
      description
      enabled
      average_po_cost
    ].freeze

    # SHOW_PAGE_ATTRIBUTES
    # an array of attributes that will be displayed on the model's show page.
    SHOW_PAGE_ATTRIBUTES = %i[
      id
      actual_cost_to_hc
      ai_enabled
      average_po_cost
      category
      country_of_origin
      customs_description
      declared_unit_cost_override
      description
      enabled
      hs_code
      in_stock
      inbound
      name
      sku
      zenventory_id
      created_at
      updated_at
    ].freeze

    # FORM_ATTRIBUTES
    # an array of attributes that will be displayed
    # on the model's form (`new` and `edit`) pages.
    FORM_ATTRIBUTES = %i[
      actual_cost_to_hc
      ai_enabled
      average_po_cost
      category
      country_of_origin
      customs_description
      declared_unit_cost_override
      description
      enabled
      hs_code
      in_stock
      inbound
      name
      sku
      zenventory_id
    ].freeze

    # COLLECTION_FILTERS
    # a hash that defines filters that can be used while searching via the search
    # field of the dashboard.
    #
    # For example to add an option to search for open resources by typing "open:"
    # in the search field:
    #
    #   COLLECTION_FILTERS = {
    #     open: ->(resources) { resources.where(open: true) }
    #   }.freeze
    COLLECTION_FILTERS = {}.freeze

    # Overwrite this method to customize how skus are displayed
    # across all pages of the admin dashboard.
    #
    def display_resource(sku)
      "SKU #{sku.sku}"
    end
  end
end
