module Flamethrower
  class CampfireRoom
    include Flamethrower::Campfire::RestApi

    attr_reader :stream
    attr_accessor :messages, :number, :name, :topic, :users

    def initialize(domain, token, params = {})
      @domain = domain
      @token = token
      @messages = Queue.new
      @number = params['id']
      @name = params['name']
      @topic = params['topic']
      @users = []
    end

    def fetch_room_info
      response = http.get("/room/#{@number}.json")
      json = JSON.parse(response.body)
      json['room']['users'].each do |user|
        @users << Flamethrower::Campfire::User.new(user)
      end
    end

    def connect
      @stream = Twitter::JSONStream.connect(:path => "/room/#{@number}/live.json", 
                                  :host => "streaming.campfirenow.com", 
                                  :auth => "#{@token}:x")
    end

    def store_messages
      @stream.each_item do |item| 
        @messages << item
      end
    end

    def retrieve_messages
      Array.new.tap do |new_array|
        until @messages.empty?
          new_array << @messages.pop
        end
      end
    end
  end
end