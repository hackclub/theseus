# frozen_string_literal: true

module HasTableSync
  RECORD_LIMIT_PER_CALL = 10_000

  extend ActiveSupport::Concern
  included do
    def self.has_table_sync(base, table, mapping, scope: nil)
      @table_sync_base = base
      @table_sync_table = table
      @table_sync_mapping = mapping
      @table_sync_scope = scope

      self.class.define_method(:mirror_to_airtable!) do |sync_id|
        headers = @table_sync_mapping.keys.map(&:to_s)
        records = (@table_sync_scope ? self.send(@table_sync_scope) : self.all).load

        records.each_slice(RECORD_LIMIT_PER_CALL) do |chunk|
          csv = CSV.generate do |csv|
            csv << headers
            chunk.each do |record|
              row = []
              @table_sync_mapping.values.each do |field|
                row << (field.class == Symbol ? record.try(field) : record.instance_eval(&field))
              end
              csv << row
            end
          end
          url = "#{ENV["AIRTABLE_BASE_URL"] || "https://api.airtable.com"}/v0/#{@table_sync_base}/#{@table_sync_table}/sync/#{sync_id}"
          res = JSON.parse(HTTP.post(
            url,
            headers: { "Authorization" => "Bearer #{Rails.application.credentials.dig(:airtable, :pat)}", "Content-Type" => "text/csv" },
            body: csv
          ))
          raise StandardError, res["error"] if res["error"]
        end
        nil
      end
    end
  end
end
