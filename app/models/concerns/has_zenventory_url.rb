# frozen_string_literal: true

module HasZenventoryUrl
  extend ActiveSupport::Concern
  included do
    def self.has_zenventory_url(format, id_field = :zenventory_id)
      self.define_method(:zenventory_url) do
        id = self.try(id_field)
        return if id.nil?

        format % id
      end
    end
  end
end
