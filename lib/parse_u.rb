def IPAddress.parse_u(i)
  if i.is_a?(Bignum)
    IPAddress::IPv6.parse_u128(i)
  else
    IPAddress::IPv4.parse_u32(i)
  end
end
