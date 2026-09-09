module LSV
  class Base < Norairrecord::Table
    def inspect = "<#{self.class.name} #{id}> #{fields.inspect}"

    def to_partial_path = "lsv/type/base"

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

      def email_column = responsible_class.instance_variable_get(:@email_column)

      attr_writer :email_column

      def find_by_email(email)
        raise ArgumentError, "no email?" if email.nil? || email.empty?
        records filter: "LOWER(TRIM({#{self.email_column}}))='#{email.downcase}'"
      end
    end

    def tracking_number = nil
    def tracking_link = nil


    def status_text = "error fetching status! poke nora"

    def source_url = fields.dig("source_rec_url", "url")
    def source_id = source_url&.split("/").last

    def icon = "📦"

    def hide_contents? = false

    def status_icon = "?"

    def shipped? = nil

    def description = nil

    def email = fields[self.class.email_column]

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
        source_record: source_url
      }.compact.to_json
    end

    alias_method :to_param, :id
  end
end
