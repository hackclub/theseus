module AirtableETL
  class AthenaStickersETLJob < AirtableETLJob
    TYPE = :letters
    FIELD_MAP = {
      public_id: "Theseus – Letter ID",
      aasm_state: "Theseus – Status",
      mailed_at: "Theseus – Mailed At",
      received_at: "Theseus – Received At",
      postage: "Theseus – Postage Cost",
    }
    BASE_KEY = "appwSxpT4lASsosUI"
    TABLE_NAME = "tblBOgmyC9RVK98wD"
  end
end

# https://airtable.com/appwSxpT4lASsosUI/tblBOgmyC9RVK98wD/viw8A7jEmV36w3zAe/recM62E73UpmG0W1C/fld65tjhaen9iv77b?copyLinkToCellOrRecordOrigin=gridView
