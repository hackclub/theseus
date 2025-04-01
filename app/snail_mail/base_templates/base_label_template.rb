class BaseLabelTemplate
  def setup_fonts(pdf)
    pdf.font_families.update(
      "comic" => {
        normal: "#{File.dirname(__FILE__)}/assets/fonts/comic sans.ttf",
      },
      "arial" => {
        normal: "#{File.dirname(__FILE__)}/assets/fonts/arial.otf",
      },
      "f25" => {
        normal: "#{File.dirname(__FILE__)}/assets/fonts/f25.ttf",
      },
      "imb" => {
        normal: "#{File.dirname(__FILE__)}/assets/fonts/imb.ttf",
      }
    )
    pdf.fallback_fonts(["arial"])
  end
end
