require "query_lens/version"
require "query_lens/configuration"
require "query_lens/engine"

module QueryLens
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
