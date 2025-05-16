module Inspect
  class IndiciaController < InspectorController
    MODEL = USPS::Indicium
    LINKED_FIELDS = %i(letter)
  end
end
