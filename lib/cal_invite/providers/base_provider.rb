# frozen_string_literal: true

# lib/cal_invite/providers/base_provider.rb
module CalInvite
  module Providers
    class BaseProvider
      attr_reader :event

      def initialize(event)
        @event = event
      end

      def generate
        raise NotImplementedError, "#{self.class} must implement #generate"
      end

      protected

      def url_encode(str)
        URI.encode_www_form_component(str.to_s)
      end
    end
  end
end
