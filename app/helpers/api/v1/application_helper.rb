module API
  module V1
    module ApplicationHelper
      def expand?(key)
        @expand.include?(key)
      end

      def expand(*keys)
        before = @expand
        @expand = @expand.dup + keys

        yield
      ensure
        @expand = before
      end
    end
  end
end