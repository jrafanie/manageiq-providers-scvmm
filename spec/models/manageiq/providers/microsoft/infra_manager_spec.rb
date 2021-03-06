describe ManageIQ::Providers::Microsoft::InfraManager do
  it ".ems_type" do
    expect(described_class.ems_type).to eq('scvmm')
  end

  it ".description" do
    expect(described_class.description).to eq('Microsoft System Center VMM')
  end

  it ".auth_url handles ipv6" do
    expect(described_class.auth_url("::1")).to eq("http://[::1]:5985/wsman")
  end

  context "#connect with ssl" do
    before do
      @e = FactoryGirl.create(:ems_microsoft, :hostname => "host", :security_protocol => "ssl", :ipaddress => "127.0.0.1")
      @e.authentications << FactoryGirl.create(:authentication, :userid => "user", :password => "pass")
    end

    it "defaults" do
      expect(described_class).to receive(:raw_connect) do |connection|
        expect(connection[:endpoint]).to match("http://host:5985/wsman")
        expect(connection[:disable_sspi]).to eq(true)
        expect(connection[:user]).to eq("user")
        expect(connection[:password]).to eq("pass")
      end

      @e.connect
    end

    it "accepts overrides" do
      expect(described_class).to receive(:raw_connect) do |connection|
        expect(connection[:endpoint]).to match("http://host2:5985/wsman")
        expect(connection[:disable_sspi]).to eq(true)
        expect(connection[:user]).to eq("user2")
        expect(connection[:password]).to eq("pass2")
      end

      @e.connect(:user => "user2", :password => "pass2", :hostname => "host2")
    end
  end

  context "#connect with kerberos" do
    before do
      @e = FactoryGirl.create(:ems_microsoft, :hostname => "host", :security_protocol => "kerberos", :realm => "pretendrealm", :ipaddress => "127.0.0.1")
      @e.authentications << FactoryGirl.create(:authentication, :userid => "user", :password => "pass")
    end

    it "defaults" do
      expect(described_class).to receive(:raw_connect) do |connection|
        expect(connection[:endpoint]).to match("http://host:5985/wsman")
        expect(connection[:disable_sspi]).to eq(false)
        expect(connection[:basic_auth_only]).to eq(false)
        expect(connection[:user]).to eq("user")
        expect(connection[:password]).to eq("pass")
        expect(connection[:realm]).to eq("pretendrealm")
      end

      @e.connect
    end

    it "accepts overrides" do
      expect(described_class).to receive(:raw_connect) do |connection|
        expect(connection[:endpoint]).to match("http://host2:5985/wsman")
        expect(connection[:disable_sspi]).to eq(false)
        expect(connection[:basic_auth_only]).to eq(false)
        expect(connection[:user]).to eq("user2")
        expect(connection[:password]).to eq("pass2")
        expect(connection[:realm]).to eq("pretendrealm")
      end

      @e.connect(:user => "user2", :password => "pass2", :hostname => "host2")
    end
  end

  context "#raw_connect with validation" do
    it "validates the connection if validate is true" do
      require 'winrm'
      connection, powershell = double, double
      params = { :endpoint => "http://host2:5985/wsman", :user => "user", :password => "password" }
      allow(WinRM::Connection).to receive(:new).with(params).and_return(connection)

      expect(connection).to receive(:shell).with(:powershell).and_return(powershell)
      expect(powershell).to receive(:run).with('hostname')

      described_class.raw_connect(params, true)
    end

    it "decrypts the password" do
      password = MiqPassword.encrypt("password")
      params = { :endpoint => "http://host2:5985/wsman", :user => "user", :password => password }

      expect(MiqPassword).to receive(:try_decrypt).with(password).and_return("password")

      described_class.raw_connect(params)
    end
  end

  context 'catalog types' do
    let(:ems) { FactoryGirl.create(:ems_microsoft) }

    it "#supported_catalog_types" do
      expect(ems.supported_catalog_types).to eq(%w(microsoft))
    end
  end
end
