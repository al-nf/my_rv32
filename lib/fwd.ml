open Hardcaml
open Signal

module Make = struct
  module I = struct
    type 'a t = {
      ex_mem_rd: 'a; [@bits 5]
      ex_mem_reg_wr: 'a; [@bits 1]
      mem_wb_rd: 'a; [@bits 5]
      mem_wb_reg_wr: 'a; [@bits 1]
      id_ex_rs1: 'a; [@bits 5]
      id_ex_rs2: 'a; [@bits 5]
    } [@@deriving hardcaml]
  end

  module O = struct
    type 'a t = {
      (* 00 no forwarding
         01 forward from MEM/WB
         10 forward from EX/MEM
         11 unused *)
      forward_a: 'a; [@bits 2]
      forward_b: 'a; [@bits 2]
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) =
    let pick rs =
      let ex_mem_fwd =
        i.ex_mem_reg_wr &: (i.ex_mem_rd <>: zero 5) &: (i.ex_mem_rd ==: rs)
      in
      let mem_wb_fwd =
        i.mem_wb_reg_wr &: (i.mem_wb_rd <>: zero 5) &: (i.mem_wb_rd ==: rs)
      in
      mux2 ex_mem_fwd (of_int ~width:2 2)
        (mux2 mem_wb_fwd (of_int ~width:2 1) (of_int ~width:2 0))
    in
    { O.forward_a = pick i.id_ex_rs1;
      O.forward_b = pick i.id_ex_rs2;
    }
end
