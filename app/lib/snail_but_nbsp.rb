# frozen_string_literal: true

# just like good ol' Snail except s/ /nbsp and s/-/endash on city line
#
# that way we don't linebreak in the middle of a zipcode when we render out in Prawn!
class SnailButNbsp < Snail
  def city_line
    super.tr(" -", " –")
  end
end
