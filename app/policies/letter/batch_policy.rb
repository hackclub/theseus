class Letter::BatchPolicy < ApplicationPolicy
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

  def edit?
    record_belongs_to_user || user_is_admin
  end

  def update?
    record_belongs_to_user || user_is_admin
  end

  def destroy?
    user_is_admin
  end

  def map_fields?
    record_belongs_to_user || user_is_admin
  end

  def set_mapping?
    record_belongs_to_user || user_is_admin
  end

  def process_form?
    record_belongs_to_user || user_is_admin
  end

  def process_batch?
    record_belongs_to_user || user_is_admin
  end

  def mark_printed?
    record_belongs_to_user || user_is_admin
  end

  def mark_mailed?
    record_belongs_to_user || user_is_admin
  end

  def update_costs?
    record_belongs_to_user || user_is_admin
  end
end 