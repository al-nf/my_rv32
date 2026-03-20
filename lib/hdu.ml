open Hardcaml
open Signal

module Make = struct
  module I = struct
    type 'a t = {
      id_ex_mem_rd: 'a; [@bits 1]
      id_ex_rd: 'a; [@bits 5]
      if_id_rs1: 'a; [@bits 5]
      if_id_rs2: 'a; [@bits 5]
    } [@@deriving hardcaml]
  end

  module O = struct
    type 'a t = {
        stall: 'a; [@bits 1]
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) = {
    O.stall = i.id_ex_mem_rd &:
    ((i.id_ex_rd ==: i.if_id_rs1) |: (i.id_ex_rd ==: i.if_id_rs2))
  };


end
