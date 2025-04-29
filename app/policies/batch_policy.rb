class BatchPolicy < ApplicationPolicy
  def index?
    user_can_warehouse
  end

  def show?
    return true if user_is_admin
    user_can_warehouse && record_belongs_to_user
  end

  def new?
    user_can_warehouse
  end

  def create?
    user_can_warehouse
  end

  def edit?
    return true if user_is_admin
    user_can_warehouse && record_belongs_to_user
  end

  def update?
    return true if user_is_admin
    user_can_warehouse && record_belongs_to_user
  end

  def destroy?
    return true if user_is_admin
    user_can_warehouse && record_belongs_to_user
  end

  def map_fields?
    return true if user_is_admin
    user_can_warehouse && record_belongs_to_user
  end

  def set_mapping?
    return true if user_is_admin
    user_can_warehouse && record_belongs_to_user
  end

  def process_batch?
    return true if user_is_admin
    user_can_warehouse && record_belongs_to_user
  end

  def process_form?
    return true if user_is_admin
    user_can_warehouse && record_belongs_to_user
  end

  def mark_printed?
    return true if user_is_admin
    user_can_warehouse && record_belongs_to_user
  end

  def mark_mailed?
    return true if user_is_admin
    user_can_warehouse && record_belongs_to_user
  end

  def update_costs?
    return true if user_is_admin
    user_can_warehouse && record_belongs_to_user
  end

  private

  def record_belongs_to_user
    user && record.user == user
  end
end 