open Hardcaml
open Signal

module Make = struct
  module I = struct
    type 'a t = {
      clk: 'a [@bits 1];
      rst: 'a [@bits 1];

      pc: 'a [@bits 32];

      rd: 'a; [@bits 5]

      reg_wr: 'a; [@bits 1]
      mem_to_reg : 'a; [@bits 1]

      alu_result: 'a; [@bits 32]
      mem_data: 'a; [@bits 32]
    } [@@deriving hardcaml]

  end

  module O = struct
    type 'a t = {
      pc: 'a [@bits 32];

      rd: 'a; [@bits 5]

      reg_wr: 'a; [@bits 1]
      mem_to_reg : 'a; [@bits 1]

      alu_result: 'a; [@bits 32]
      mem_data: 'a; [@bits 32]
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) =
    let spec = Reg_spec.create ~clock:i.clk ~reset:i.rst () in {
      O.pc = reg spec ~enable:vdd i.pc;

      O.rd = reg spec ~enable:vdd i.rd;

      O.reg_wr = reg spec ~enable:vdd i.reg_wr;
      O.mem_to_reg  = reg spec ~enable:vdd i.mem_to_reg;

      O.alu_result = reg spec ~enable:vdd i.alu_result;
      O.mem_data = reg spec ~enable:vdd i.mem_data;
    };

end
