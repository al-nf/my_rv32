open Hardcaml
open Signal

module Make = struct
  module I = struct
    type 'a t = {
       clk: 'a [@bits 1];
       rst: 'a [@bits 1];
       pc_in: 'a [@bits 32];
       pc_wr: 'a [@bits 1];
       stall: 'a [@bits 1];
    } [@@deriving hardcaml]
  end

  module O = struct
    type 'a t = {
      pc_out: 'a [@bits 32];
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) =
    let spec = Reg_spec.create ~clock:i.clk ~reset:i.rst () in
    let pc = reg_fb spec ~enable:vdd ~width:32 ~f:(fun pc ->
      (* pc_wr wins over stall so a taken branch still redirects even while
         a load-use stall is asserted. *)
      mux2 i.pc_wr i.pc_in
        (mux2 i.stall pc (pc +:. 4))
    ) in
    { O.pc_out = pc }
end
