require "administrate/base_dashboard"

module Warehouse
  class OrderDashboard < Administrate::BaseDashboard
    # ATTRIBUTE_TYPES
    # a hash that describes the type of each of the model's fields.
    #
    # Each different type represents an Administrate::Field object,
    # which determines how the attribute is displayed
    # on pages throughout the dashboard.
    ATTRIBUTE_TYPES = {
      id: Field::Number,
      aasm_state: Field::String,
      address: Field::BelongsTo,
      canceled_at: Field::DateTime,
      carrier: Field::String,
      dispatched_at: Field::DateTime,
      hc_id: Field::String,
      idempotency_key: Field::String,
      internal_notes: Field::Text,
      line_items: Field::HasMany,
      mailed_at: Field::DateTime,
      postage_cost: Field::String.with_options(searchable: false),
      recipient_email: Field::String,
      service: Field::String,
      skus: Field::HasMany,
      source_tag: Field::BelongsTo,
      surprise: Field::Boolean,
      tracking_number: Field::String,
      user: Field::BelongsTo,
      user_facing_description: Field::String,
      user_facing_title: Field::String,
      weight: Field::String.with_options(searchable: false),
      zenventory_id: Field::Number,
      created_at: Field::DateTime,
      updated_at: Field::DateTime,
    }.freeze

    # COLLECTION_ATTRIBUTES
    # an array of attributes that will be displayed on the model's index page.
    #
    # By default, it's limited to four items to reduce clutter on index pages.
    # Feel free to add, remove, or rearrange items.
    COLLECTION_ATTRIBUTES = %i[
      hc_id
      aasm_state
      user
      source_tag
    ].freeze

    # SHOW_PAGE_ATTRIBUTES
    # an array of attributes that will be displayed on the model's show page.
    SHOW_PAGE_ATTRIBUTES = %i[
      id
      aasm_state
      address
      canceled_at
      carrier
      dispatched_at
      hc_id
      idempotency_key
      internal_notes
      line_items
      mailed_at
      postage_cost
      recipient_email
      service
      skus
      source_tag
      surprise
      tracking_number
      user
      user_facing_description
      user_facing_title
      weight
      zenventory_id
      created_at
      updated_at
    ].freeze

    # FORM_ATTRIBUTES
    # an array of attributes that will be displayed
    # on the model's form (`new` and `edit`) pages.
    FORM_ATTRIBUTES = %i[
      aasm_state
      address
      canceled_at
      carrier
      dispatched_at
      hc_id
      idempotency_key
      internal_notes
      line_items
      mailed_at
      postage_cost
      recipient_email
      service
      skus
      source_tag
      surprise
      tracking_number
      user
      user_facing_description
      user_facing_title
      weight
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

    # Overwrite this method to customize how orders are displayed
    # across all pages of the admin dashboard.
    #
    def display_resource(order)
      "Order ##{order.hc_id}"
    end
  end
end
