require 'socket'
require 'ipaddr'

class Addrinfo
  include Comparable

  def <=>(other)
    if self.ipv4? && other.ipv4? || self.ipv6? && other.ipv6?
      self.to_string <=> other.to_string
    elsif self.ipv4? && other.ipv6?
      -1
    elsif self.ipv6? && other.ipv4?
      1
    end
  end

  def to_s
    IPAddr.new(self.ip_unpack[0].split('%')[0]).to_s
  end

  def to_string
    IPAddr.new(self.ip_unpack[0].split('%')[0]).to_string
  end

  def self.ip_tests
    instance_methods.sort.
        map(&:to_s).
        select { |m| m =~ /\Aipv4/ || m =~ /\Aipv6/ }.
        select { |m| m =~ /\?\z/ }.
        map(&:to_sym)
  end
end
