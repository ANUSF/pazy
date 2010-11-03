module Pazy::Helpers
  def mask(hash, shift)
    (hash >> shift) & 0x1f
  end

  def bitcount(n)
    n -= (n >> 1) & 0x55555555
    n = (n & 0x33333333) + ((n >> 2) & 0x33333333)
    n = (n & 0x0f0f0f0f) + ((n >> 4) & 0x0f0f0f0f)
    n += n >> 8
    (n + (n >> 16)) & 0x3f
  end

  def index_for_bit(bitmap, bit)
    bitcount(bitmap & (bit - 1))
  end

  def bitpos_and_index(bitmap, hash, shift)
    bit = 1 << mask(hash, shift)
    [bit, index_for_bit(bitmap, bit)]
  end
end
