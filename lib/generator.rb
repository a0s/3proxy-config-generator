HostPort = Struct.new(:host, :port)

class Generator
  def self.generate(opts = {})
    c = new(opts)
    c.parse
    c.divide
    c
  end

  def initialize(opts = {})
    @argv = opts[:argv] || []
    @template = opts[:template]
    @src_addr = []
    @src_port = []
    @dst_addr = []
    @auth_iponly = []
  end

  def u32(data)
    IPAddress::IPv4.parse_u32(data)
  end

  def u128(data)
    IPAddress::IPv6.parse_u128(data)
  end

  def parse_ip_range(data)
    a1, a2 = data.split('-').map { |a| IPAddress(a) }
    fail("Wrong interval `#{data}'") if a1.class != a2.class
    (a1.to_i..a2.to_i).to_a.map { |i| a1.ipv4? ? u32(i) : u128(i) }.map(&:to_s)
  end

  def parse_ip_range_(data)
    a1, a2 = data.split('+')
    a1, a2 = IPAddress(a1), a2.to_i
    (a1.to_i...a1.to_i+a2).to_a.map { |i| a1.ipv4? ? u32(i) : u128(i) }.map(&:to_s)
  end

  def parse_port_range(data)
    a1, a2 = data.split('-')
    (a1.to_i..a2.to_i).to_a
  end

  def parse_port_range_(data)
    a1, a2 = data.split('+')
    (a1.to_i...a1.to_i+a2.to_i).to_a
  end

  def parse
    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: generator [options]'

      opts.separator ''
      opts.separator 'Specific options:'

      opts.on('-a', '--src-addr ADDR', Array,
              'Internal addresses. Can be list, range or start+size',
              '  a1b1::1005',
              '  a1b1::1005,a1b1::1006',
              '  a1b1::1005-a1b1::100a',
              '  a1b1::1005+6 is equivalent to a1b1::1005-a1b1::100a') do |addr|
        addr.each do |ad|
          if ad.include?('-')
            @src_addr += parse_ip_range(ad)
          elsif ad.include?('+')
            @src_addr += parse_ip_range_(ad)
          else
            @src_addr << IPAddress(ad).to_s
          end
        end
      end

      opts.on('-p', '--src-port PORT', Array,
              'Internal ports. Can be list, range or start+size',
              '  80',
              '  80,8080',
              '  8080-8084 ports from 8080 to 8084',
              '  8080+5 is equivalent to 8080-8084') do |port|
        port.each do |po|
          if po.include?('-')
            @src_port += parse_port_range(po)
          elsif po.include?('+')
            @src_port += parse_port_range_(po)
          else
            @src_port << po.to_i
          end
        end
      end

      opts.on('--dst-as-src',
              'Dst address same as src address') do
        @dst_addr = @src_addr
      end

      opts.on('-d', '--dst-addr ADDR', Array,
              'External addresses. Can be list, range or start+size',
              '  a1b1::1005',
              '  a1b1::1005,a1b1::1006',
              '  a1b1::1005-a1b1::100a',
              '  a1b1::1005+6 is equivalent to a1b1::1005-a1b1::100a') do |addr|
        addr.each do |ad|
          if ad.include?('-')
            @dst_addr += parse_ip_range(ad)
          elsif ad.include?('+')
            @dst_addr += parse_ip_range_(ad)
          else
            @dst_addr << IPAddress(ad).to_s
          end
        end
      end

      opts.on('-i', '--auth-iponly ADDR', Array,
              'List of authorized ips. Can be list, range or start+size') do |addr|
        addr.each do |ad|
          if ad.include?('-')
            @auth_iponly += parse_ip_range(ad)
          elsif ad.include?('+')
            @auth_iponly += parse_ip_range_(ad)
          else
            @auth_iponly << IPAddress(ad).to_s
          end
        end
      end

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end

    opt_parser.parse(@argv)

    self
  end

  #        /-> OUTPUT
  # INPUT ---> OUTPUT   ratio > 1
  #        \-> OUTPUT
  #
  # INPUT -\
  # INPUT ---> OUTPUT   ratio <= 1
  # INPUT -/

  def divide
    inputs = []
    @src_addr.each do |sa|
      @src_port.each do |sp|
        inputs << HostPort.new(sa, sp)
      end
    end
    outputs = @dst_addr.map { |da| HostPort.new(da) }

    @devided = {}

    ratio = outputs.size.to_f / inputs.size

    if ratio > 1
      outputs.each_with_index do |output1, idx|
        input1 = Array.wrap(inputs[(idx / ratio).floor])
        @devided[input1] ||= []
        @devided[input1] << output1
      end
    else
      inputs.each_with_index do |input1, idx|
        output1 = Array.wrap(outputs[(idx * ratio).floor])
        @devided[output1] ||= []
        @devided[output1] << input1
      end
      @devided = @devided.invert
    end

    self
  end

  def rules
    rules = []

    if @auth_iponly.present?
      rules << 'auth iponly'
      rules << 'allow * %s' % [@auth_iponly.join(',')]
    end

    @devided.each do |src, dst|
      if dst.size > 1
        if dst.all? { |dst1| IPAddress(dst1.host).ipv6? }
          resolver = '-6'
        elsif dst.all? { |dst1| IPAddress(dst1.host).ipv4? }
          resolver = '-4'
        else
          resolver = '-64'
        end

        weights = Array.new(dst.size) { (1000.0 / dst.size).to_i }
        weights[0] = 1000 - weights[1..-1].inject(:+) if weights.size > 2
        dst.each_with_index do |dst1, idx|
          rules << 'parent %s extip %s 0' % [weights[idx], dst1.host]
        end
        src.each do |src1|
          rules << 'socks -i%s -p%s %s' % [src1.host, src1.port, resolver]
        end

      else
        Array(src).each do |src1|
          rules << 'socks -i%s -p%s -e%s %s' % [src1.host, src1.port, dst[0].host, IPAddress(dst[0].host).ipv6? ? '-6' : '-4']
        end
      end
    end

    rules << 'flush'
  end

  def to_s
    str = ''
    str += @template if @template.present?
    str += "\n"
    str + rules.join("\n")
  end
end
