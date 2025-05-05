require "administrate/field/base"

class Administrate::Field::Array < Administrate::Field::Base
  def to_s
    data
  end

  def self.permitted_attribute(attr, _options = nil)
    { attr => [] }
  end

  def self.searchable?
    true
  end

  def searchable?
    self.class.searchable?
  end

  def collection
    data || []
  end

  def include_blank
    options.fetch(:include_blank, true)
  end

  def value
    data
  end
end 