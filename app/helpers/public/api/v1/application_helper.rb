module Public
  module API
    module V1
      module ApplicationHelper
        def expand?(key)
          @expand.include?(key)
        end

        def if_expand(key, &block)
          if expand?(key)
            yield
          end
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
end
