module HasAddress
  extend ActiveSupport::Concern

  included do
    belongs_to :address
    accepts_nested_attributes_for :address, update_only: true
  end
end
