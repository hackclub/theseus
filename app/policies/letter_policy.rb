class LetterPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def new?
    true
  end

  def create?
    true
  end

  def by_tag?
    true
  end

  def edit?
    record_belongs_to_user || user_is_admin
  end

  def update?
    record_belongs_to_user || user_is_admin
  end

  def destroy?
    user_is_admin
  end

  def generate_label?
    record_belongs_to_user || user_is_admin
  end

  def buy_indicia?
    record_belongs_to_user || user_is_admin
  end

  def mark_printed?
    record_belongs_to_user || user_is_admin
  end

  def mark_mailed?
    record_belongs_to_user || user_is_admin
  end

  def mark_received?
    record_belongs_to_user || user_is_admin
  end

  def clear_label?
    record_belongs_to_user || user_is_admin
  end

  def preview_template?
    Rails.env.development? && (record_belongs_to_user || user_is_admin)
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

  private

  def record_belongs_to_user
    user && (record.user == user || record.batch&.user == user)
  end
end
