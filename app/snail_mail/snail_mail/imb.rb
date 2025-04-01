module SnailMail
    class IMb
        attr_reader :letter
        def initialize(letter)
            @letter = letter
        end

        def generate
            barcode_id    = "00"  # no OEL
            stid          = "310" # no address corrections – no printed endorsements, but! IV-MTR!
            mailer_id     = letter.mailer_id.mid
            serial_number = letter.imb_serial_number
            routing_code  = letter.address.postal_code.gsub(/[^0-9]/, '') # zip(+dpc?) but no dash

            Imb.new(
              barcode_id,
              stid,
              mailer_id,
              serial_number,
              routing_code
            ).barcode_letters
        end
    end
end