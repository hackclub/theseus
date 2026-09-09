module SnailMail
  module Components
    class TemplateBase < PageComponent
      # Base class for all mail templates
      # This allows us to use descendants to automatically discover templates

      def self.abstract?
        false
      end

      def self.template_description
        "A mail template"
      end
    end
  end
end
