# frozen_string_literal: true

class Warehouse::PurchaseOrderPolicy < ApplicationPolicy
  def index?
    user_is_admin
  end

  def show?
    user_is_admin
  end

  def new?
    user_is_admin
  end

  def create?
    user_is_admin
  end

  def edit?
    user_is_admin && record.draft?
  end

  def update?
    user_is_admin && record.draft?
  end

  def destroy?
    user_is_admin && record.draft?
  end

  def send_to_zenventory?
    user_is_admin && record.draft?
  end

  def sync?
    user_is_admin && record.zenventory_id.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
