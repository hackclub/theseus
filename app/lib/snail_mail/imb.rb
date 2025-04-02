module SnailMail
    class IMb
        attr_reader :letter
        def initialize(letter)
            @letter = letter
        end

        def generate
            barcode_id    = "00"  # no OEL
            stid          = "310" # no address corrections – no printed endorsements, but! IV-MTR!
            mailer_id     = letter.usps_mailer_id.mid
            serial_number = letter.imb_serial_number
            routing_code  = letter.address.postal_code.gsub(/[^0-9]/, '') # zip(+dpc?) but no dash

            begin
                Imb::Barcode.new(
                  barcode_id,
                  stid,
                  mailer_id,
                  serial_number,
                  routing_code
                ).barcode_letters
            rescue ArgumentError => e
                Rails.logger.warn("Bad IMb input: #{e.message} @ MID #{mailer_id} SN #{serial_number} RC #{routing_code}")
                ""
            end
        end
    end
end