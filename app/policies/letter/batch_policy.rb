class Letter::BatchPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def new?
    user.present?
  end

  def create?
    user.present?
  end

  def edit?
    user.present?
  end

  def update?
    user.present?
  end

  def destroy?
    user.admin?
  end

  def map_fields?
    user.present?
  end

  def set_mapping?
    user.present?
  end

  def process_form?
    user.present?
  end

  def process_batch?
    user.present?
  end

  def mark_printed?
    user.present?
  end

  def mark_mailed?
    user.present?
  end

  def update_costs?
    user.present?
  end

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
