module Flamethrower
  class EventConnection < EventMachine::Connection
    include Flamethrower::Server

    attr_accessor :server

    def unbind
      @server.connections.delete(self)
    end

    def stop
      irc_channels.map do |channel|
        channel.to_campfire.kill_thread!
      end
    end

    def streams_alive?
      irc_channels.any? do |channel|
        channel.to_campfire.alive?
      end
    end
  end

  class EventServer
    attr_reader :host, :port, :campfire_connection, :connections

    def initialize(host, port, domain, token)
      @host = host || "0.0.0.0"
      @port = port || 6667
      @domain = domain
      @token = token
      @connections = []
    end

    def start
      EventMachine::run do
        FLAMETHROWER_LOGGER.info "Flamethrower started at #{@host}:#{@port} on domain #{@domain}"
        @signature = EventMachine::start_server(@host, @port, EventConnection) do |connection|
          @connections << connection
          connection.server = self
          connection.campfire_connection = Flamethrower::Campfire::Connection.new(@domain, @token, connection)
        end
      end
    end

    def stop
      FLAMETHROWER_LOGGER.info("Killing room threads")
      @connections.each do |connection|
        connection.stop
      end
      EventMachine.stop_server(@signature)
      die_safely
    end

    private

    def die_safely
      FLAMETHROWER_LOGGER.info("Waiting for streams and connections to die")
      if any_streams_alive? || any_connections_alive?
        EventMachine.add_periodic_timer(1) { die_safely }
      else
        FLAMETHROWER_LOGGER.info("Done.")
        EventMachine.stop
      end
    end

    def any_streams_alive?
      @connections.any? do |connection|
        connection.streams_alive?
      end
    end

    def any_connections_alive?
      @connections.size <= 0
    end
  end
end
