# This contract needs 3 arguments:
# 0. pubkey, used to identify token owner
# 1. signature, signature used to present ownership
# 2. string of `,` separated array denoting outputs to sign.
# It's up to transaction assembler to arrange outputs, this script
# only cares that correct data are signed.
if ARGV.length != 3
  raise "Wrong number of arguments!"
end

def hex_to_bin(s)
  if s.start_with?("0x")
    s = s[2..-1]
  end
  [s].pack("H*")
end

OUTPUT_INDEX_ERR = "Output index error!".freeze

tx = CKB.load_tx
blake2b = Blake2b.new

tx["inputs"].each_with_index do |input, i|
  blake2b.update(input["hash"])
  blake2b.update(input["index"].to_s)
end
ARGV[2].split(",").each do |output_index|
  output_index = output_index.to_i
  if output = tx["outputs"][output_index]
    blake2b.update(output["capacity"].to_s)
    blake2b.update(CKB.load_script_hash(output_index, CKB::Source::OUTPUT, CKB::HashType::LOCK))
    if hash = CKB.load_script_hash(output_index, CKB::Source::OUTPUT, CKB::HashType::TYPE)
      blake2b.update(hash)
    end
  else
    raise OUTPUT_INDEX_ERR
  end
end

hash = blake2b.final

pubkey = ARGV[0]
signature = ARGV[1]

unless Secp256k1.verify(hex_to_bin(pubkey), hex_to_bin(signature), hash)
  raise "Signature verification error!"
end
