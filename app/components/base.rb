# frozen_string_literal: true

class Components::Base < Phlex::HTML
  include Components
  register_value_helper :current_user
  register_value_helper :admin_tool
  register_value_helper :icon_svg
  register_value_helper :policy

  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::ButtonTo

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
