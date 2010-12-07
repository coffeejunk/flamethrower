module Flamethrower
  module Irc
    class Channel

      attr_accessor :name, :topic, :modes, :mode

      def initialize(name, campfire_channel=nil)
        @users = []
        @name = name
        @modes = ["t"]
        @campfire_channel = campfire_channel
      end

      def mode
        "+#{@modes.join}"
      end

      def to_campfire
        @campfire_channel
      end

      def users=(users)
        @users = users
      end

      def users
        @users.concat(@campfire_channel.users.map(&:to_irc))
      end

    end
  end
end
