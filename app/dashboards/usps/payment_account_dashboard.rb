require "administrate/base_dashboard"

module USPS
  class PaymentAccountDashboard < Administrate::BaseDashboard
    # ATTRIBUTE_TYPES
    # a hash that describes the type of each of the model's fields.
    #
    # Each different type represents an Administrate::Field object,
    # which determines how the attribute is displayed
    # on pages throughout the dashboard.
    ATTRIBUTE_TYPES = {
      id: Field::Number,
      account_number: Field::String,
      account_type: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
      manifest_mid: Field::String,
      name: Field::String,
      permit_number: Field::String,
      permit_zip: Field::String,
      usps_mailer_id: Field::BelongsTo,
      created_at: Field::DateTime,
      updated_at: Field::DateTime,
      ach: Field::Boolean,
    }.freeze

    # COLLECTION_ATTRIBUTES
    # an array of attributes that will be displayed on the model's index page.
    #
    # By default, it's limited to four items to reduce clutter on index pages.
    # Feel free to add, remove, or rearrange items.
    COLLECTION_ATTRIBUTES = %i[
      id
      account_number
      account_type
      manifest_mid
    ].freeze

    # SHOW_PAGE_ATTRIBUTES
    # an array of attributes that will be displayed on the model's show page.
    SHOW_PAGE_ATTRIBUTES = %i[
      id
      account_number
      account_type
      manifest_mid
      name
      permit_number
      permit_zip
      usps_mailer_id
      created_at
      updated_at
      ach
    ].freeze

    # FORM_ATTRIBUTES
    # an array of attributes that will be displayed
    # on the model's form (`new` and `edit`) pages.
    FORM_ATTRIBUTES = %i[
      account_number
      account_type
      manifest_mid
      name
      permit_number
      permit_zip
      usps_mailer_id
      ach
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

    # Overwrite this method to customize how payment accounts are displayed
    # across all pages of the admin dashboard.
    #
    # def display_resource(payment_account)
    #   "USPS::PaymentAccount ##{payment_account.id}"
    # end
  end
end
