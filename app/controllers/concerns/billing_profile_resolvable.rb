module BillingProfileResolvable
  extend ActiveSupport::Concern

  private

  def find_billing_profile(id, user: current_user)
    return nil if id.blank?
    user.billing_profiles.find_by(id: id) ||
      BillingProfile.find_by_public_id(id)&.then { |p| p if p.user == user }
  end
end
