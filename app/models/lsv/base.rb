module LSV
  class Base < Norairrecord::Table
    def inspect
      "<#{self.class.name} #{id}> #{fields.inspect}"
    end

    def to_partial_path
      "lsv/type/base"
    end

    class << self
      def responsible_class
        # this is FUCKING DISGUSTING
        return self if superclass == Base
        if superclass.singleton_class.method_defined?(:responsible_class)
          superclass.responsible_class
        else
          self
        end
      end

      def records(**args)
        return [] unless table_name
        raise "don't use Shipment directly!" unless self < Base
        super
      end

      def email_column
        responsible_class.instance_variable_get(:@email_column)
      end

      attr_writer :email_column

      def find_by_email(email)
        raise ArgumentError, "no email?" if email.nil? || email.empty?
        records :filter => "LOWER(TRIM({#{self.email_column}}))='#{email.downcase}'"
      end
    end

    def tracking_number
      nil
    end

    def tracking_link
      nil
    end

    def status_text
      "error fetching status! poke nora"
    end

    def source_url
      fields.dig("source_rec_url", "url")
    end

    def source_id
      source_url&.split("/").last
    end

    def icon
      "📦"
    end

    def hide_contents?
      false
    end

    def status_icon
      "?"
    end

    def shipped?
      nil
    end

    def description
      nil
    end

    def email
      fields[self.class.email_column]
    end

    def to_json(options = {})
      {
        id:,
        date:,
        tracking_link:,
        tracking_number:,
        type: self.class.name,
        type_text:,
        title: title_text,
        shipped: shipped?,
        icon:,
        description:,
        source_record: source_url,
      }.compact.to_json
    end

    def to_param
      id
    end
  end
end
