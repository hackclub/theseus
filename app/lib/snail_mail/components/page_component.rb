module SnailMail
  module Components
    class PageComponent < BaseComponent
      def before_template
        start_new_page unless page_number > 0
        register_fonts
        fallback_fonts %w[arial noto sym]
      end

      private

      def register_fonts
        font_families.update(
          "comic" => { normal: font_path("comic sans.ttf") },
          "arial" => { normal: font_path("arial.otf") },
          "f25" => { normal: font_path("f25.ttf") },
          "imb" => { normal: font_path("imb.ttf") },
          "gohu" => { normal: font_path("gohu.ttf") },
          "noto" => { normal: font_path("noto sans regular.ttf") },
          "times" => { normal: font_path("times.ttf") },
          "sym" => { normal: font_path("apple-symbols.ttf") },
        )
      end

      def font_path(font_name) = File.join(Rails.root, "app", "lib", "snail_mail", "assets", "fonts", font_name)
    end
  end
end
