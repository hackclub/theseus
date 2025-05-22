module AirtableETL
  class AirtableETLJob < ApplicationJob
    def perform
      type = self.class::TYPE
      raise "type must be one of: :letters, :warehouse_orders" unless [:letters, :warehouse_orders].include?(type)
      base_key = self.class::BASE_KEY
      table_name = self.class::TABLE_NAME
      field_map = self.class::FIELD_MAP

      table = Class.new(Norairrecord::Table) do
        self.base_key = base_key
        self.table_name = table_name
      end

      recs = table.records

      case type
      when :letters
        recs.each do |rec|
          public_id = rec[field_map[:public_id]]

          letter = Letter.find_by_public_id(public_id)
          if letter.nil?
            Rails.logger.error("Letter not found for public_id: #{public_id}")
            rec[field_map[:aasm_state]] = "not_found"
            next
          end

          field_map.each do |theseus_field, airtable_field|
            res = letter.send(theseus_field)
            if res.is_a?(BigDecimal)
              res = res.to_f
            end

            if res.is_a?(Time) && rec[airtable_field].is_a?(String)
              begin
                airtable_time = Time.parse(rec[airtable_field])
                next if res.to_i == airtable_time.to_i
              rescue ArgumentError
              end
            end

            next if res == rec[airtable_field]
            puts "Updating #{airtable_field} for #{public_id} from #{rec[airtable_field]} to #{res}"
            rec[airtable_field] = res
          end
        end
      when :warehouse_orders
        raise NotImplementedError
      end

      recs.reject! do |rec|
        rec.instance_variable_get(:@updated_keys).empty?
      end

      table.batch_update(recs)
    end
  end
end
