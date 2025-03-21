class Flavor
  class << self
    def comma(name)
      name && ", #{name}"
    end
    def time_based_greeting(name: nil)
      current_hour = Time.now.hour
      case current_hour
      when 0..11
        "Good morning#{comma(name)}!"
      when 12..17
        "Good afternoon#{comma(name)}!"
      else
        "Good evening#{comma(name)}..."
      end
    end
    def greeting(name: nil)
      [
        time_based_greeting(name:),
        "despite everything, it's still #{name || 'you'}...",
        "hey #{name || 'you'}!"
      ].sample
    end
    def good_job_flavor
      [
        "it ain't much, but it's honest work...",
        "good enough for government work...",
        "who up jobbing they good?"
      ].sample
    end
  end
end
