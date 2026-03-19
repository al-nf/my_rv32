open Hardcaml
open Signal

module Make = struct
  module I = struct
    type 'a t = {
      instr: 'a; [@bits 32]
    } [@@deriving hardcaml]
  end

  module O = struct
    type 'a t = {
      imm_i: 'a; [@bits 32]
      imm_s: 'a; [@bits 32]
      imm_b: 'a; [@bits 32]
      imm_u: 'a; [@bits 32]
      imm_j: 'a; [@bits 32]
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) = {
    O.imm_i = concat_msb [
      repeat (select i.instr 31 31) 20;
      select i.instr 31 20;
    ];
    O.imm_s = concat_msb [
      repeat (select i.instr 31 31) 20;
      select i.instr 31 25;
      select i.instr 11 7;
    ];
    O.imm_b = concat_msb [
      repeat (select i.instr 31 31) 20;
      select i.instr 31 31;
      select i.instr 7 7;
      select i.instr 30 25;
      select i.instr 11 8;
      zero 1;
    ];
    O.imm_u = concat_msb [
      select i.instr 31 12;
      zero 12;
    ];
    O.imm_j = concat_msb [
      repeat (select i.instr 31 31) 11;
      select i.instr 31 31;
      select i.instr 19 12;
      select i.instr 20 20;
      select i.instr 30 21;
      zero 1;
    ];
  }
end
