require File.dirname(__FILE__) + '/spec_helper'

describe 'Generator#rules' do
  def r(data)
    Generator.generate(argv: data).rules
  end

  it "input count == output count" do
    expect(r ["--src-addr", "2.2.2.2", "--src-port", "17000+4",
              "--dst-addr", "11::f000+4",
              "--auth-iponly", "1.1.1.1"])
        .to eq ["auth iponly",
                "allow * 1.1.1.1",
                "socks -i2.2.2.2 -p17000 -e11::f000 -6",
                "socks -i2.2.2.2 -p17001 -e11::f001 -6",
                "socks -i2.2.2.2 -p17002 -e11::f002 -6",
                "socks -i2.2.2.2 -p17003 -e11::f003 -6",
                "flush"]
  end
  it "input count < output count" do
    expect(r ["--src-addr", "2.2.2.2", "--src-port", "17000+3",
              "--dst-addr", "11::f000+4",
              "--auth-iponly", "1.1.1.1"])
        .to eq ["auth iponly",
                "allow * 1.1.1.1",
                "parent 500 extip 11::f000 0",
                "parent 500 extip 11::f001 0",
                "socks -i2.2.2.2 -p17000 -6",
                "socks -i2.2.2.2 -p17001 -e11::f002 -6",
                "socks -i2.2.2.2 -p17002 -e11::f003 -6",
                "flush"]
  end

  it "input count > output count" do
    expect(r ["--src-addr", "2.2.2.2", "--src-port", "17000+4",
              "--dst-addr", "11::f000+3",
              "--auth-iponly", "1.1.1.1"])
        .to eq ["auth iponly",
                "allow * 1.1.1.1",
                "socks -i2.2.2.2 -p17000 -e11::f000 -6",
                "socks -i2.2.2.2 -p17001 -e11::f000 -6",
                "socks -i2.2.2.2 -p17002 -e11::f001 -6",
                "socks -i2.2.2.2 -p17003 -e11::f002 -6",
                "flush"]
  end

  context 'with --http-proxy' do
    it "input count == output count" do
      expect(r ["--src-addr", "2.2.2.2", "--src-port", "17000+4", "--http-proxy", "1000",
                "--dst-addr", "11::f000+4",
                "--auth-iponly", "1.1.1.1"])
          .to eq ["auth iponly",
                  "allow * 1.1.1.1",
                  "socks -i2.2.2.2 -p17000 -e11::f000 -6",
                  "proxy -i2.2.2.2 -p18000 -e11::f000 -6",
                  "socks -i2.2.2.2 -p17001 -e11::f001 -6",
                  "proxy -i2.2.2.2 -p18001 -e11::f001 -6",
                  "socks -i2.2.2.2 -p17002 -e11::f002 -6",
                  "proxy -i2.2.2.2 -p18002 -e11::f002 -6",
                  "socks -i2.2.2.2 -p17003 -e11::f003 -6",
                  "proxy -i2.2.2.2 -p18003 -e11::f003 -6",
                  "flush"]
    end
    it "input count < output count" do
      expect(r ["--src-addr", "2.2.2.2", "--src-port", "17000+3", "--http-proxy=-10000",
                "--dst-addr", "11::f000+4",
                "--auth-iponly", "1.1.1.1"])
          .to eq ["auth iponly",
                  "allow * 1.1.1.1",
                  "parent 500 extip 11::f000 0",
                  "parent 500 extip 11::f001 0",
                  "socks -i2.2.2.2 -p17000 -6",
                  "proxy -i2.2.2.2 -p7000 -6",
                  "socks -i2.2.2.2 -p17001 -e11::f002 -6",
                  "proxy -i2.2.2.2 -p7001 -e11::f002 -6",
                  "socks -i2.2.2.2 -p17002 -e11::f003 -6",
                  "proxy -i2.2.2.2 -p7002 -e11::f003 -6",
                  "flush"]
    end

    it "input count > output count" do
      expect(r ["--src-addr", "2.2.2.2", "--src-port", "17000+4", "--http-proxy", "+10000",
                "--dst-addr", "11::f000+3",
                "--auth-iponly", "1.1.1.1"])
          .to eq ["auth iponly",
                  "allow * 1.1.1.1",
                  "socks -i2.2.2.2 -p17000 -e11::f000 -6",
                  "proxy -i2.2.2.2 -p27000 -e11::f000 -6",
                  "socks -i2.2.2.2 -p17001 -e11::f000 -6",
                  "proxy -i2.2.2.2 -p27001 -e11::f000 -6",
                  "socks -i2.2.2.2 -p17002 -e11::f001 -6",
                  "proxy -i2.2.2.2 -p27002 -e11::f001 -6",
                  "socks -i2.2.2.2 -p17003 -e11::f002 -6",
                  "proxy -i2.2.2.2 -p27003 -e11::f002 -6",
                  "flush"]
    end
  end
end
