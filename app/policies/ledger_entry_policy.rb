class LedgerEntryPolicy < ApplicationPolicy
  def index? = true
  def show? = record.billing_profile.user == user || user_is_admin

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.is_admin?
        scope.all
      else
        scope.where(billing_profile: user.billing_profiles)
      end
    end
  end
end
