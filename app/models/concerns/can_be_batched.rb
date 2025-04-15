module CanBeBatched
  extend ActiveSupport::Concern

  included do
    belongs_to :batch, optional: true

    scope :in_batch, -> { where.not(batch_id: nil) }
    scope :not_in_batch, -> { where(batch_id: nil) }
  end
end
