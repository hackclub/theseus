module Public
  class LeaderboardsController < ApplicationController
    layout 'public/frameable'

    before_action :set_framed

    def this_week
      @tab = :this_week
      @lb = fetch_leaderboard(:week, Time.current.beginning_of_week)
      render :show
    end

    def this_month
      @tab = :this_month
      @lb = fetch_leaderboard(:month, Time.current.beginning_of_month)
      render :show
    end

    def all_time
      @tab = :all_time
      @lb = fetch_leaderboard(:all_time)
      render :show
    end

    private

    def set_framed
      @framed = true
    end

    def fetch_leaderboard(period, start_time = nil)
      cache_key = "letter_leaderboard/#{period}"
      cache_key += "/#{start_time.to_i}" if start_time

      Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
        query = ::User.joins(:letters)
                     .where(letters: { aasm_state: ['mailed', 'received'] })
                     .group('users.id')
                     .select('users.*, COUNT(letters.id) as letter_count')
                     .having('COUNT(letters.id) > 0')
                     .order('letter_count DESC')
                     .limit(100)

        query = query.where('letters.mailed_at >= ?', start_time) if start_time
        query
      end
    end
  end
end