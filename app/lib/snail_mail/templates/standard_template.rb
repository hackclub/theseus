require_relative '../base_template'

module SnailMail
  module Templates
    class StandardTemplate < BaseTemplate
      def self.template_name
        "standard"
      end
      
      def self.template_size
        :standard
      end
      
      def self.template_description
        "Basic standard 4x6 label template"
      end
      
      def render(pdf, letter)
        # Simple layout for a standard 4x6 label
        
        # Render return address in top left
        render_return_address(pdf, letter, 15, 270, 130, 70)
        
        # Render destination address
        render_destination_address(
          pdf, 
          letter, 
          105, 
          180, 
          250, 
          100,
          { 
            size: 12, 
            valign: :center 
          }
        )
        
        # Render IMb barcode
        render_imb(pdf, letter, 100, 90, 280, 30)
        
        # Render QR code
        render_qr_code(pdf, letter, 15, 180, 75)
      end
    end
  end
end 