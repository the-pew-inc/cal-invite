# lib/cal_invite/providers/base_provider.rb
module CalInvite
  module Providers
    class BaseProvider
      attr_reader :event

      def initialize(event)
        @event = event
      end

      def generate
        raise NotImplementedError
      end

      def update_attendees
        raise NotImplementedError
      end
    end
  end
end
