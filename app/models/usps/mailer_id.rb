# == Schema Information
#
# Table name: usps_mailer_ids
#
#  id         :bigint           not null, primary key
#  crid       :string
#  mid        :string
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class USPS::MailerId < ApplicationRecord
  def display_name
    "#{name} (#{crid}/#{mid})"
  end
end
