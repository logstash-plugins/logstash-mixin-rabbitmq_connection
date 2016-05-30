# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "march_hare"
require "java"

# Common functionality for the rabbitmq input/output
module LogStash
  module PluginMixins
    module RabbitMQConnection
      EXCHANGE_TYPES = ["fanout", "direct", "topic", "x-consistent-hash", "x-modulus-hash"]

      HareInfo = Struct.new(:connection, :channel, :exchange, :queue)

      def self.included(base)
        base.extend(self)
        base.setup_rabbitmq_connection_config
      end

      def setup_rabbitmq_connection_config
        # RabbitMQ server address
        config :host, :validate => :string, :required => true

        # RabbitMQ port to connect on
        config :port, :validate => :number, :default => 5672

        # RabbitMQ username
        config :user, :validate => :string, :default => "guest"

        # RabbitMQ password
        config :password, :validate => :password, :default => "guest"

        # The vhost (virtual host) to use. If you don't know what this
        # is, leave the default. With the exception of the default
        # vhost ("/"), names of vhosts should not begin with a forward
        # slash.
        config :vhost, :validate => :string, :default => "/"

        # Enable or disable SSL.
        # Note that by default remote certificate verification is off.
        # Specify ssl_certificate_path and ssl_certificate_password if you need
        # certificate verification
        config :ssl, :validate => :boolean

        # Version of the SSL protocol to use.
        config :ssl_version, :validate => :string, :default => "TLSv1.2"

        # Path to an SSL certificate in PKCS12 (.p12) format used for verifying the remote host
        config :ssl_certificate_path, :validate => :path

        # Password for the encrypted PKCS12 (.p12) certificate file specified in ssl_certificate_path
        config :ssl_certificate_password, :validate => :string

        # Set this to automatically recover from a broken connection. You almost certainly don't want to override this!!!
        config :automatic_recovery, :validate => :boolean, :default => true

        # Time in seconds to wait before retrying a connection
        config :connect_retry_interval, :validate => :number, :default => 1

        # The default connection timeout in milliseconds. If not specified the timeout is infinite.
        config :connection_timeout, :validate => :number

        # Heartbeat delay in seconds. If unspecified no heartbeats will be sent
        config :heartbeat, :validate => :number

        # Passive queue creation? Useful for checking queue existance without modifying server state
        config :passive, :validate => :boolean, :default => false

        # Extra queue arguments as an array.
        # To make a RabbitMQ queue mirrored, use: `{"x-ha-policy" => "all"}`
        config :arguments, :validate => :array, :default => {}
      end

      def conn_str
        "amqp://#{@user}@#{@host}:#{@port}#{@vhost}"
      end

      def close_connection
        @rabbitmq_connection_stopping = true
        @hare_info.channel.close if channel_open?
        @hare_info.connection.close if connection_open?
      end

      def rabbitmq_settings
        return @rabbitmq_settings if @rabbitmq_settings

        s = {
          :vhost => @vhost,
          :host  => @host,
          :port  => @port,
          :user  => @user,
          :automatic_recovery => @automatic_recovery,
          :pass => @password ? @password.value : "guest",
        }

        s[:timeout] = @connection_timeout || 0
        s[:heartbeat] = @heartbeat || 0

        if @ssl
          s[:tls] = @ssl_version

          cert_path = @ssl_certificate_path
          cert_pass = @ssl_certificate_password

          if !!cert_path ^ !!cert_pass
            raise LogStash::ConfigurationError, "RabbitMQ requires both ssl_certificate_path AND ssl_certificate_password to be set!"
          end

          s[:tls_certificate_path] = cert_path
          s[:tls_certificate_password] = cert_pass
        end


        @rabbitmq_settings = s
      end

      def connect!
        @hare_info = connect() unless @hare_info # Don't duplicate the conn!
      rescue MarchHare::Exception => e
        @logger.error("RabbitMQ connection error, will retry.",
                      :message => e.message,
                      :exception => e.class.name,
                      :backtrace => e.backtrace)

        sleep_for_retry
        retry
      end

      def channel_open?
        @hare_info && @hare_info.channel && @hare_info.channel.open?
      end

      def connection_open?
        @hare_info && @hare_info.connection && @hare_info.connection.open?
      end

      def connected?
        return nil unless @hare_info && @hare_info.connection
        @hare_info.connection.connected?
      end

      private

      def declare_exchange!(channel, exchange, exchange_type, durable)
        @logger.debug? && @logger.debug("Declaring an exchange", :name => exchange,
                      :type => exchange_type, :durable => durable)
        exchange = channel.exchange(exchange, :type => exchange_type.to_sym, :durable => durable)
        @logger.debug? && @logger.debug("Exchange declared")
        exchange
      rescue StandardError => e
        @logger.error("Could not declare exchange!",
                      :exchange => exchange, :type => exchange_type,
                      :durable => durable, :error_class => e.class.name,
                      :error_message => e.message, :backtrace => e.backtrace)
        raise e
      end

      def connect
        @logger.debug? && @logger.debug("Connecting to RabbitMQ. Settings: #{rabbitmq_settings.inspect}")

        connection = MarchHare.connect(rabbitmq_settings)


        connection.on_blocked { @logger.warn("RabbitMQ output blocked! Check your RabbitMQ instance!") }
        connection.on_unblocked { @logger.warn("RabbitMQ output unblocked!") }

        channel = connection.create_channel
        @logger.info("Connected to RabbitMQ at #{rabbitmq_settings[:host]}")

        HareInfo.new(connection, channel)
      end

      def sleep_for_retry
        Stud.stoppable_sleep(@connect_retry_interval) { @rabbitmq_connection_stopping }
      end
    end
  end
end
