class Letter < ApplicationRecord
  belongs_to :mailer_id
  belongs_to :address
end
