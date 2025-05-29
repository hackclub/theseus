module Public
  class MapsController < ApplicationController
    include Frameable
    layout "public/frameable"

    def show
      @return_path = public_root_path
    end
  end
end
