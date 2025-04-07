module SnailMail
  module FIM
    class << self
      FIM_D = [
        1, 1, 1, 0, 1, 0, 1, 1, 1
      ]

      FIM_HEIGHT = 45
      FIM_ELEMENT_WIDTH = 2.25

      def render_fim_d(pdf, x = 245)
        render_fim(pdf, FIM_D, x)
      end

      def render_fim(pdf, fim, x)
        pdf.fill do
          lx = 0
          fim.each do |e|
            pdf.rectangle([ x + lx, pdf.bounds.height ], FIM_ELEMENT_WIDTH, FIM_HEIGHT) if e == 1
            lx += FIM_ELEMENT_WIDTH * 2 # 1 for bar, 1 for spacer
          end
        end
      end
    end
  end
end
