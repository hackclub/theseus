module AirtableETL
  class HCBWelcomeETLJob < AirtableETLJob
    TYPE = :letters
    FIELD_MAP = {
      public_id: "mail - welcome letter ID",
      aasm_state: "mail - welcome status"
    }
    BASE_KEY = "apppALh5FEOKkhjLR"
    TABLE_NAME = "tblctmRFEeluG4do7"
  end
end
