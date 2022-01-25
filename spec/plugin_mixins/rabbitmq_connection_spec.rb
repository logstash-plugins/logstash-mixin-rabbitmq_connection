# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/plugin_mixins/rabbitmq_connection"
require "stud/temporary"

class TestPlugin < LogStash::Outputs::Base
  include LogStash::PluginMixins::RabbitMQConnection

  def register
    connect!
  end

  def connection_url(connection)
  end
end

describe LogStash::PluginMixins::RabbitMQConnection do
  let(:klass) { TestPlugin }
  let(:default_port) { 5672 }
  let(:host) { "localhost" }
  let(:port) { default_port }
  let(:rabbitmq_settings) {
    {
      "host" => host
    }
  }
  let(:instance) {
    klass.new(rabbitmq_settings)
  }
  let(:hare_info) { instance.instance_variable_get(:@hare_info) }



  shared_examples_for 'it sets the addresses correctly' do
    let(:file) { Stud::Temporary.file }
    let(:path) { file.path }

    it "should set addresses to the expected value" do
      host.each_with_index do |_, index|
        puts(expected_values[index])
        expect(instance.rabbitmq_settings[:addresses][index]).to eql(expected_values[index])
      end
    end

    it "should insert the correct number of address entries" do
      expect(instance.rabbitmq_settings[:addresses].length).to eql(host.count)
    end
  end

  describe "rabbitmq_settings" do
    let(:file) { Stud::Temporary.file }
    let(:path) { file.path }
    after { File.unlink(path)}

    let(:rabbitmq_settings) { super().merge({"connection_timeout" => 123,
                                           "heartbeat" => 456,
                                           "ssl" => true,
                                           "ssl_version" => "TLSv1.1",
                                           "ssl_certificate_path" => path,
                                           "ssl_certificate_password" => "123"}) }

    it "should set the timeout to the expected value" do
      expect(instance.rabbitmq_settings[:timeout]).to eql(rabbitmq_settings["connection_timeout"])
    end

    it "should set heartbeat to the expected value" do
      expect(instance.rabbitmq_settings[:heartbeat]).to eql(rabbitmq_settings["heartbeat"])
    end

    it "should set tls to the expected value" do
      expect(instance.rabbitmq_settings[:tls]).to eql("TLSv1.1")
    end

    it "should set tls_certificate_path to the expected value" do
      expect(instance.rabbitmq_settings[:tls_certificate_path]).to eql(rabbitmq_settings["ssl_certificate_path"])
    end

    it "should set tls_certificate_password to the expected value" do
      expect(instance.rabbitmq_settings[:tls_certificate_password]).to eql(rabbitmq_settings["ssl_certificate_password"])
    end

    context 'with host names' do
      let (:host) {%w(localhost rmq.elastic.co rmq.local)}
      let (:expected_values) {%w(localhost:5672 rmq.elastic.co:5672 rmq.local:5672)}

      it_behaves_like 'it sets the addresses correctly'
    end

    context 'with host names including ports' do
      let (:host) {%w(localhost:123 rmq.elastic.co:234 rmq.local:345)}
      let (:expected_values) {%w(localhost:123 rmq.elastic.co:234 rmq.local:345)}

      it_behaves_like 'it sets the addresses correctly'
    end

    context 'with ipv4 ip addresses' do
      let (:host) {%w(127.0.0.1 192.168.1.1 192.168.1.2)}
      let (:expected_values) {%w(127.0.0.1:5672 192.168.1.1:5672 192.168.1.2:5672)}

      it_behaves_like 'it sets the addresses correctly'
    end

    context 'with ipv4 ip addresses including ports' do
      let (:host) {%w(127.0.0.1:123 192.168.1.1:234 192.168.1.2:345)}
      let (:expected_values) {host}

      it_behaves_like 'it sets the addresses correctly'
    end

    context 'with ipv6 addresses' do
      let (:host) {%w(::1 fe80::1c86:a2e:4bec:4a9f%en0 2406:da00:ff00::36e1:f792 [::1] [fe80::1c86:a2e:4bec:4a9f%en0] [2406:da00:ff00::36e1:f792])}
      let (:expected_values) {%w([::1]:5672 [fe80::1c86:a2e:4bec:4a9f%en0]:5672 [2406:da00:ff00::36e1:f792]:5672 [::1]:5672 [fe80::1c86:a2e:4bec:4a9f%en0]:5672 [2406:da00:ff00::36e1:f792]:5672)}
      it_behaves_like 'it sets the addresses correctly'
    end

    context 'with ipv6 addresses including ports' do
      let (:host) {%w([::1]:456 [fe80::1c86:a2e:4bec:4a9f%en0]:457 [2406:da00:ff00::36e1:f792]:458)}
      let (:expected_values) {%w([::1]:456 [fe80::1c86:a2e:4bec:4a9f%en0]:457 [2406:da00:ff00::36e1:f792]:458)}
      it_behaves_like 'it sets the addresses correctly'
    end

    context 'with a custom port' do
      let(:port) { 123 }
      let(:rabbitmq_settings) { super().merge({"port" => port})}

      context 'with hostnames' do
        let (:host) {%w(localhost rmq.elastic.co rmq.local)}
        let (:expected_values) {%w(localhost:123 rmq.elastic.co:123 rmq.local:123)}

        it_behaves_like 'it sets the addresses correctly'
      end


      context 'with ipv4 ip addresses' do
        let (:host) {%w(127.0.0.1 192.168.1.1 192.168.1.2)}
        let (:expected_values) {%w(127.0.0.1:123 192.168.1.1:123 192.168.1.2:123)}

        it_behaves_like 'it sets the addresses correctly'
      end

      context 'with ipv6 addresses' do
        let (:host) {%w(::1 fe80::1c86:a2e:4bec:4a9f%en0 2406:da00:ff00::36e1:f792 [::1] [fe80::1c86:a2e:4bec:4a9f%en0] [2406:da00:ff00::36e1:f792])}
        let (:expected_values) {%w([::1]:123 [fe80::1c86:a2e:4bec:4a9f%en0]:123 [2406:da00:ff00::36e1:f792]:123 [::1]:123 [fe80::1c86:a2e:4bec:4a9f%en0]:123 [2406:da00:ff00::36e1:f792]:123)}
        it_behaves_like 'it sets the addresses correctly'
      end
    end
  end

  describe "ssl enabled, but no verification" do
    let(:rabbitmq_settings) { super().merge({"connection_timeout" => 123,
                                           "heartbeat" => 456,
                                           "ssl" => true}) }

    it "should not have any certificates set" do
      expect(instance.rabbitmq_settings[:tls_certificate_password]).to be nil
      expect(instance.rabbitmq_settings[:tls_certificate_path]).to be nil
    end

  end

  context "when connected" do
    let(:connection) { double("MarchHare Connection") }
    let(:channel) { double("Channel") }

    before do
      allow(instance).to receive(:connect!).and_call_original
      allow(::MarchHare).to receive(:connect).and_return(connection)
      allow(connection).to receive(:create_channel).and_return(channel)
      allow(connection).to receive(:on_blocked)
      allow(connection).to receive(:on_unblocked)
      allow(connection).to receive(:on_shutdown)

      instance.register
    end

    describe "#register" do
      subject { instance }

      it "should create cleanly" do
        expect(subject).to be_a(klass)
      end

      it "should connect" do
        expect(subject).to have_received(:connect!).once
      end
    end

    describe "#connect!" do
      subject { hare_info }

      it "should set @hare_info correctly" do
        expect(subject).to be_a(LogStash::PluginMixins::RabbitMQConnection::HareInfo)
      end

      it "should set @connection correctly" do
        expect(subject.connection).to eql(connection)
      end

      it "should set the channel correctly" do
        expect(subject.channel).to eql(channel)
      end
    end
  end

  # If the connection encounters an exception during its initial
  # connection attempt we must handle that. Subsequent errors should be
  # handled by the automatic retry mechanism built-in to MarchHare
  describe "initial connection exceptions" do
    subject { instance }

    before do
      allow(subject).to receive(:sleep_for_retry)


      i = 0
      allow(subject).to receive(:connect) do
        i += 1
        if i == 1
          raise(MarchHare::ConnectionRefused, "Error!")
        else
          double("connection")
        end
      end

      subject.send(:connect!)
    end

    it "should retry its connection when conn fails" do
      expect(subject).to have_received(:connect).twice
    end

    it "should sleep between retries" do
      expect(subject).to have_received(:sleep_for_retry).once
    end
  end
end
