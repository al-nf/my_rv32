open Hardcaml
open Signal

module Make = struct
  module I = struct
    type 'a t = {
      clk: 'a [@bits 1];
      rst: 'a [@bits 1];
      instr: 'a [@bits 32];
      pc: 'a [@bits 32];

      stall: 'a [@bits 1];
      flush: 'a [@bits 1];
    } [@@deriving hardcaml]
  end

  module O = struct
    type 'a t = {
      instr: 'a [@bits 32];
      pc: 'a [@bits 32];
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) =
    let spec = Reg_spec.create ~clock:i.clk ~reset:i.rst () in
    let hold = i.stall &: ~: (i.flush) in
    let en   = ~: hold in
    let sel x = mux2 i.flush (zero (width x)) x in
    {
      O.instr = reg spec ~enable:en (sel i.instr);
      O.pc    = reg spec ~enable:en (sel i.pc);
    }
end
