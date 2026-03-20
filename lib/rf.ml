open Hardcaml
open Signal

module Make = struct
  module I = struct
    type 'a t = {
      rs1: 'a [@bits 5];
      rs2: 'a [@bits 5];
      rd: 'a [@bits 5];
      clk: 'a [@bits 1];
      data_in: 'a [@bits 32];
      reg_wr: 'a [@bits 1];
    } [@@deriving hardcaml]
  end

  module O = struct
    type 'a t = {
      data_out1: 'a [@bits 32];
      data_out2: 'a [@bits 32];
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) =
    let regs = multiport_memory 32
    ~write_ports:[|{
        write_clock = i.clk;
        write_enable = i.reg_wr &: (i.rd <>: zero 5);
        write_address = i.rd;
        write_data = i.data_in;
    }|]
    ~read_addresses:[|
      i.rs1;
      i.rs2;
    |]
    in
    { O.data_out1 = regs.(0); O.data_out2 = regs.(1) }
end
