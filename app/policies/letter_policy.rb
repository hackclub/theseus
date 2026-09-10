class LetterPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record_belongs_to_user || user_is_admin
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
    user&.can_use_indicia? && (record_belongs_to_user || user_is_admin)
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

  def clear_indicium?
    user_is_admin
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

  # Batch and queue owners get their own letters back even when the letter's
  # own user is whoever submitted it — the batch and queue pages link straight
  # at letter_path.
  def record_belongs_to_user
    user && (record.user == user || record.batch&.user == user || record.queue&.user == user)
  end
end
