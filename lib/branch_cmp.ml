open Hardcaml
open Signal

module Make = struct
  module I = struct
    type 'a t = {
      rs1_data: 'a; [@bits 32]
      rs2_data: 'a; [@bits 32]
      funct3: 'a; [@bits 3]
    } [@@deriving hardcaml]
  end

  module O = struct
    type 'a t = {
      taken: 'a; [@bits 1]
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) =
    let is_eq = i.rs1_data ==: i.rs2_data in
    let is_lt = i.rs1_data <+ i.rs2_data in
    let is_ltu = i.rs1_data <: i.rs2_data in
    { O.taken = Signal.mux i.funct3 [
        is_eq;      (* 000: BEQ *)
        ~: is_eq;   (* 001: BNE *)
        gnd;        (* 010: reserved *)
        gnd;        (* 011: reserved *)
        is_lt;      (* 100: BLT (signed) *)
        ~: is_lt;   (* 101: BGE (signed) *)
        is_ltu;     (* 110: BLTU (unsigned) *)
        ~: is_ltu;  (* 111: BGEU (unsigned) *)
      ]
    }
end
