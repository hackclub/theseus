class Warehouse::BatchPolicy < ApplicationPolicy
  def index?
    user_can_warehouse
  end

  def show?
    user_can_warehouse
  end

  def new?
    user_can_warehouse
  end

  def create?
    user_can_warehouse
  end

  def edit?
    user_can_warehouse
  end

  def update?
    user_can_warehouse
  end

  def destroy?
    user_is_admin
  end

  def map_fields?
    user_can_warehouse
  end

  def set_mapping?
    user_can_warehouse
  end

  def process_form?
    user_can_warehouse
  end

  def process_batch?
    user_can_warehouse
  end

  def mark_printed?
    user_can_warehouse
  end

  def mark_mailed?
    user_can_warehouse
  end

  def update_costs?
    user_can_warehouse
  end
end 