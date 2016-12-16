#Usage

    apt-get install ruby ruby-bundler git
    git clone https://github.com/orangeudav/3proxy-config-generator.git
    cd 3proxy-config-generator
    bundle install --deployment
    bundle exec ./3proxy-config-generator -h
    
##Get list of ips
    > bundle exec ./ips
    +---------------------------+---------------------+
    | 10.18.0.5                 | ipv4 ipv4_private   |
    | 127.0.0.1                 | ipv4 ipv4_loopback  |
    | 168.16.12.73              | ipv4                |
    | 2a03:b2c0:2:a0::1363:f000 | ipv6                |
    | 2a03:b2c0:2:a0::1363:f001 | ipv6                |
    | ::1                       | ipv6 ipv6_loopback  |
    | fe83::a2cb:8aff:fea1:1229 | ipv6 ipv6_linklocal |
    +---------------------------+---------------------+

#Examples
##One ip4 with ports to many ip6

    bundle exec ./3proxy-config-generator --src-addr 188.176.52.33 --src-port 40000+4 \
    --dst-addr 2a03:b0c0:2:d0::1073:f000+4 --auth-iponly 138.40.22.189   

Result

    log
    nserver 8.8.8.8
    nserver 8.8.4.4
    nserver 2001:4860:4860::8888
    nserver 2001:4860:4860::8844
    nscache6 65536
    nscache 65536
    setgid 65534
    setuid 65534
    
    auth iponly
    allow * 138.40.22.189
    socks -i188.176.52.33 -p40000 -e2a03:b0c0:2:d0::1073:f000 -6
    flush
    
    auth iponly
    allow * 138.40.22.189
    socks -i188.176.52.33 -p40001 -e2a03:b0c0:2:d0::1073:f001 -6
    flush
    
    auth iponly
    allow * 138.40.22.189
    socks -i188.176.52.33 -p40002 -e2a03:b0c0:2:d0::1073:f002 -6
    flush
    
    auth iponly
    allow * 138.40.22.189
    socks -i188.176.52.33 -p40003 -e2a03:b0c0:2:d0::1073:f003 -6
    flush
    
##Many ip6
    
    bundle exec ./3proxy-config-generator --src-addr a2a2::e000-a2a2::e003 --src-port 40000 \
    --dst-as-src --auth-iponly 138.40.22.189

Result
    
    log
    nserver 8.8.8.8
    nserver 8.8.4.4
    nserver 2001:4860:4860::8888
    nserver 2001:4860:4860::8844
    nscache6 65536
    nscache 65536
    setgid 65534
    setuid 65534
    
    auth iponly
    allow * 138.40.22.189
    socks -ia2a2::e000 -p40000 -ea2a2::e000 -6
    flush
    
    auth iponly
    allow * 138.40.22.189
    socks -ia2a2::e001 -p40000 -ea2a2::e001 -6
    flush
    
    auth iponly
    allow * 138.40.22.189
    socks -ia2a2::e002 -p40000 -ea2a2::e002 -6
    flush
    
    auth iponly
    allow * 138.40.22.189
    socks -ia2a2::e003 -p40000 -ea2a2::e003 -6
    flush

##Random output

    bundle exec ./3proxy-config-generator --src-addr aaaa::e000 --src-port 40000 \
    --dst-addr cccc::0000+4  --auth-iponly 138.40.22.189
    
Result

    log
    nserver 8.8.8.8
    nserver 8.8.4.4
    nserver 2001:4860:4860::8888
    nserver 2001:4860:4860::8844
    nscache6 65536
    nscache 65536
    setgid 65534
    setuid 65534
    
    auth iponly
    allow * 138.40.22.189
    parent 250 extip cccc:: 0
    parent 250 extip cccc::1 0
    parent 250 extip cccc::2 0
    parent 250 extip cccc::3 0
    socks -iaaaa::e000 -p40000 -6
    flush
