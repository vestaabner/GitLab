# frozen_string_literal: true

module Gitlab
  module ServiceDeskEmail
    class << self
      include Gitlab::Email::Common

      def config
        Gitlab.config.service_desk_email
      end

      def key_from_address(address)
        wildcard_address = config&.address
        return unless wildcard_address

        Gitlab::IncomingEmail.key_from_address(address, wildcard_address: wildcard_address)
      end

      def address_for_key(key)
        return if config.address.blank?

        config.address.sub(WILDCARD_PLACEHOLDER, key)
      end
    end
  end
end
