class Letter::Queue < ApplicationRecord
  belongs_to :user
  has_many :letters, foreign_key: :letter_queue_id
  has_many :letter_batches, class_name: "Letter::Batch", foreign_key: :letter_queue_id
  belongs_to :letter_mailer_id, class_name: "USPS::MailerId", foreign_key: "letter_mailer_id_id", optional: true
  belongs_to :letter_return_address, class_name: "ReturnAddress", optional: true

  before_validation :set_slug, on: :create

  validates :slug, uniqueness: true, presence: true
  validates :letter_height, :letter_width, :letter_weight, presence: true, numericality: { greater_than: 0 }
  validates :letter_mailer_id, presence: true
  validates :letter_return_address, presence: true, on: :process
  validates :letter_processing_category, presence: true

  def create_letter!(address, params)
    letter = letters.build(
      address:,
      height: letter_height,
      width: letter_width,
      weight: letter_weight,
      return_address: letter_return_address,
      return_address_name: letter_return_address_name,
      usps_mailer_id: letter_mailer_id,
      processing_category: letter_processing_category,
      tags: tags,
      aasm_state: "queued",
      **params,
    )
    letter.save!
    letter
  end

  def make_batch(user:)
    ActiveRecord::Base.transaction do
      batch = letter_batches.build(
        aasm_state: :fields_mapped,
        letter_height: letter_height,
        letter_width: letter_width,
        letter_weight: letter_weight,
        letter_processing_category: letter_processing_category,
        letter_mailer_id_id: letter_mailer_id_id,
        letter_return_address_id: letter_return_address_id,
        letter_return_address_name: letter_return_address_name,
        user_facing_title: user_facing_title,
        tags: tags,
        letter_queue_id: id,
        user: user
      )
      batch.save!
      letters.queued.each do |letter|
        letter.batch_id = batch.id
        letter.batch_from_queue
        letter.save!
      end
      batch
    end
  end

  def to_param
    slug
  end

  private

  def set_slug
    self.slug = self.name.parameterize
  end
end
