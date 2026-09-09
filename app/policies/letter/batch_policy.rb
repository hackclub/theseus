class Letter::BatchPolicy < ApplicationPolicy
  def index? = user.present?

  def show? = record_belongs_to_user || user_is_admin

  def new? = user.present?

  def create? = user.present?

  def edit? = record_belongs_to_user || user_is_admin

  alias_method :update?, :edit?

  def destroy? = user.admin?

  def map_fields? = record_belongs_to_user || user_is_admin

  alias_method :set_mapping?, :map_fields?
  alias_method :process_form?, :map_fields?
  alias_method :process_batch?, :map_fields?

  def refund_overpayment? = user_is_admin

  def process_batch_with_indicia?
    (record_belongs_to_user || user_is_admin) && user.can_use_indicia?
  end

  alias_method :mark_printed?, :edit?
  alias_method :mark_mailed?, :mark_printed?
  alias_method :update_costs?, :show?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user.present?
        scope.where(user: user)
      else
        scope.none
      end
    end
  end
end
