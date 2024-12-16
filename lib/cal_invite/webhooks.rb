# lib/cal_invite/webhooks.rb
module CalInvite
  class Webhooks
    class << self
      def register(provider, event_uid, callback_url)
        provider_instance = CalInvite::Providers.const_get(provider.to_s.camelize).new(nil)
        provider_instance.register_webhook(event_uid, callback_url)
      end

      def verify_signature(request)
        return false unless CalInvite.configuration.webhook_secret

        signature = request.headers['X-Calendar-Signature']
        data = request.raw_post
        expected = OpenSSL::HMAC.hexdigest('SHA256',
                                         CalInvite.configuration.webhook_secret,
                                         data)

        ActiveSupport::SecurityUtils.secure_compare(signature, expected)
      end
    end
  end
end
