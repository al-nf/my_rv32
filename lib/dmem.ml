open Hardcaml
open Signal

module Make (Config: sig val size: int end) = struct
  open Config
  module I = struct
    type 'a t = {
      clk: 'a [@bits 1];
      address: 'a [@bits 32];
      data_in: 'a [@bits 32];
      mem_rd: 'a [@bits 1];
      mem_wr: 'a [@bits 1];
    } [@@deriving hardcaml]
  end

  module O = struct
    type 'a t = {
      data_out: 'a [@bits 32];
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) =
    let mem = multiport_memory size
    ~write_ports:[|{
        write_clock = i.clk;
        write_enable = i.mem_wr;
        write_address = i.address;
        write_data = i.data_in;
    }|]
    ~read_addresses:[|
      i.address;
    |]
    in
    { O.data_out = mem.(0)};

end
