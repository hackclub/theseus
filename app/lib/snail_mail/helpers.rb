module SnailMail
  module Helpers
    def image_path(image_name)
      File.join(Rails.root, "app", "lib", "snail_mail", "assets", "images", image_name)
    end
  end
end
