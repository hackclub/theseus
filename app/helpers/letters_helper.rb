module LettersHelper
  def status_color(state)
    case state.to_s
    when "mailed", "received" then "var(--green)"
    when "printed", "processed" then "color-mix(in srgb, var(--green) 60%, GrayText)"
    when "queued" then "var(--yellow)"
    when "failed" then "var(--red)"
    else "GrayText"
    end
  end
end
