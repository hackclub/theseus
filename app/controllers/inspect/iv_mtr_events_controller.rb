module Inspect
  class IVMTREventsController < InspectorController
    MODEL = USPS::IVMTR::Event
    LINKED_FIELDS = %i(letter)

    private
  end
end
