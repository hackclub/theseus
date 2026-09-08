class BillingProfilePolicy < ApplicationPolicy
  def index? = true
  def show? = record_belongs_to_user || user_is_admin
  def new? = true
  def create? = true
  def destroy? = record_belongs_to_user || user_is_admin

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.is_admin?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
