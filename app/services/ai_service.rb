class AIService
  class << self
    def client
      @client ||= OpenAI::Client.new
    end

    def fix_address(row, field_mapping)
      # Create a hash of the address fields for translation
      address_data = {
        "first_name" => row[field_mapping["first_name"]],
        "last_name" => row[field_mapping["last_name"]],
        "line_1" => row[field_mapping["line_1"]],
        "line_2" => row[field_mapping["line_2"]],
        "city" => row[field_mapping["city"]],
        "state" => row[field_mapping["state"]],
        "postal_code" => row[field_mapping["postal_code"]],
        "country" => row[field_mapping["country"]],
      }

      # Get translated address
      translated = gptize_address(field_mapping.keys, address_data)

      # Return the translated fields, passing through email and phone directly
      {
        first_name: address_data["first_name"]&.presence,
        last_name: address_data["last_name"]&.presence,
        line_1: translated["line_1"]&.presence,
        line_2: translated["line_2"]&.presence,
        city: translated["city"]&.presence,
        state: translated["state"]&.presence,
        postal_code: translated["postal_code"]&.presence,
        country: translated["country"]&.presence,
        phone_number: row[field_mapping["phone_number"]]&.presence,
        email: row[field_mapping["email"]]&.presence,
      }
    end

    private

    def gptize_address(fields, order)
      # Filter out email and phone from fields to translate
      address_fields = fields - ["email", "phone_number"]

      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          response_format: {
            type: "json_schema",
            json_schema: {
              name: "postal_address",
              schema: {
                strict: true,
                type: "object",
                additionalProperties: false,
                properties: {
                  line_1: { type: "string", description: "Street address only, no city/state/zip" },
                  line_2: { type: "string", description: "Secondary address info (apt, suite, etc) or overflow from line_1 if needed" },
                  city: { type: "string", description: "City name only, no state/zip" },
                  state: { type: "string", description: "State/province/region code only" },
                  postal_code: { type: "string", description: "Postal code only" },
                  country: { type: "string", description: "ISO 3166-1 alpha-2 country code" },
                },
                required: ["line_1", "city", "state", "postal_code", "country"],
              },
            },
          },
          messages: [{
            role: "user",
            content: <<~PROMPT,
              Please translate and format this address for international mail delivery:
              1. Translate to English using Latin characters
              2. Handle location information:
                 - If line_2 contains city/state (e.g., "Jebel Ali, Dubai"), move to proper fields
                 - For PO Box addresses, keep PO Box in line_1, remove location from line_2
                 - Never leave city/state information in line_2
              3. For country codes:
                 - Use ISO 3166-1 alpha-2 format (e.g., 'US', 'GB', 'JP')
                 - Convert localized names to codes (e.g., "MAGYARORSZÁG" -> "HU")
              4. Preserve special characters and formatting (building numbers, floor numbers)
              5. IMPORTANT: Never lose any information! If in doubt, keep it in the address

              Address to format:
              #{address_fields.map { |field| order[field] && "#{field}: #{order[field]}" }.compact.join("\n")}
            PROMPT
          }],
          temperature: 0.8,
        },
      )

      JSON.parse(response.dig("choices", 0, "message", "content"))
    end
  end
end
