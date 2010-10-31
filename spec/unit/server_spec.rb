require File.join(File.dirname(__FILE__), "../spec_helper")

describe Flamethrower::Server do
  before do
    @server = Flamethrower::MockServer.new
    @server.stub!(:send_data)
    @server.stub!(:puts)
    @server.current_user = Flamethrower::IrcUser.new :user => 'user', :nick => 'nick', :host => 'host', :realname => 'realname'
  end

  describe "#send_message" do
    it "sends the message to the client" do
      message = "message"
      @server.should_receive(:send_message).with("message")
      @server.send_message(message)
    end

    it "should send the data across the wire" do
      message = "message"
      @server.should_receive(:send_data).with("message\r\n")
      @server.send_message(message)
    end
  end

  describe "#send_messages" do
    it "sends a list of messages to the client" do
      @server.should_receive(:send_message).exactly(2).times
      @server.send_messages("one", "two")
    end

    it "yields to the block to allow more messages" do
      @server.should_receive(:send_message).exactly(3).times
      @server.send_messages("one", "two") do |messages|
        messages << "three"
      end
    end
  end

  context "when a user connects" do

    it "sends motd" do
      @server.should_receive(:send_motd)
      @server.post_init
    end

    it "sends an auto-join" do
      @server.should_receive(:send_join)
      @server.post_init
    end

    it "sends the current topic" do
      @server.should_receive(:send_topic)
      @server.post_init
    end

    it "sends a list of userlist" do
      @server.should_receive(:send_userlist)
      @server.post_init
    end
  end

  describe "IRCcommands" do
    
    it "should have the correct MOTD format" do
      @server.send_motd.should == [
        ":host 375 nick :MOTD",
        ":host 372 nick :Welcome to Flamethrower",
        ":host 376 nick :/End of /MOTD command"
      ]
    end

    it "should have the correct JOIN format" do
      @server.send_join.should == [
        ":nick!user@host JOIN :&flamethrower",
        "host MODE &flamethrower +t"
      ]
    end

    it "should have the correct TOPIC format" do
      @server.send_topic.should == ":host 332 nick &flamethrower :Welcome to Flamethrower"
    end

    it "should have the correct USERLIST format" do
      @server.send_userlist(["bob"]).should == [
        ":host 353 nick = &flamethrower :@nick bob",
        ":host 366 nick &flamethrower :/End of /NAMES list"
      ]
    end
  end

end