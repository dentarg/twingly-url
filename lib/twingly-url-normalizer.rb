require 'postrank-uri'
require 'domainatrix'
require 'uri'

# TODO
# * Handle blogspot.se -> blogspot.com

module Twingly
  module URL
    class Normalizer
      def self.normalize(potential_urls)
        extract_urls(potential_urls).map do |url|
          normalize_url(url)
        end
      end

      def self.extract_urls(potential_urls)
        PostRank::URI.extract(potential_urls)
      end

      def self.normalize_url(url)
        subdomain = Domainatrix.parse(url).subdomain
        uri = URI.parse(url)
        if subdomain.empty?
          uri.host = "www.#{uri.host}"
        end
        uri.to_s
      end
    end
  end
end

