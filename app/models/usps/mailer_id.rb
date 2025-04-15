# == Schema Information
#
# Table name: usps_mailer_ids
#
#  id              :bigint           not null, primary key
#  crid            :string
#  mid             :string
#  name            :string
#  rollover_count  :integer
#  sequence_number :bigint
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class USPS::MailerId < ApplicationRecord
  def display_name
    "#{name} (#{crid}/#{mid})"
  end

  def sn_length
    15 - mid.length
  end

  def max_sn
    (10**sn_length) - 1
  end

  def next_sn_and_rollover
    transaction do
      lock!
      self.sequence_number ||= 0
      self.rollover_count ||= 0
      self.sequence_number += 1
      if self.sequence_number > max_sn
        self.sequence_number = 1
        self.rollover_count += 1
      end
      save!
    end
    [ sequence_number, rollover_count ]
  end
end
