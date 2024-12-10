# lib/calendar_invites/webhooks.rb
module CalendarInvites
  class Webhooks
    class << self
      def register(provider, event_uid, callback_url)
        provider_instance = CalendarInvites::Providers.const_get(provider.to_s.camelize).new(nil)
        provider_instance.register_webhook(event_uid, callback_url)
      end

      def verify_signature(request)
        return false unless CalendarInvites.configuration.webhook_secret

        signature = request.headers['X-Calendar-Signature']
        data = request.raw_post
        expected = OpenSSL::HMAC.hexdigest('SHA256',
                                         CalendarInvites.configuration.webhook_secret,
                                         data)

        ActiveSupport::SecurityUtils.secure_compare(signature, expected)
      end
    end
  end
end
