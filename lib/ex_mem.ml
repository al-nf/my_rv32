open Hardcaml
open Signal

module Make = struct
  module I = struct
    type 'a t = {
      clk: 'a [@bits 1];
      rst: 'a [@bits 1];

      pc: 'a [@bits 32];

      rd: 'a; [@bits 5]
      funct3: 'a; [@bits 3]

      mem_rd: 'a; [@bits 1]
      mem_wr: 'a; [@bits 1]
      reg_wr: 'a; [@bits 1]
      branch: 'a; [@bits 1]
      jal: 'a; [@bits 1]
      jalr: 'a; [@bits 1]
      mem_to_reg : 'a; [@bits 1]

      alu_result: 'a; [@bits 32]
      rs2_data: 'a; [@bits 32]

      stall: 'a; [@bits 1]
    } [@@deriving hardcaml]

  end

  module O = struct
    type 'a t = {
      pc: 'a [@bits 32];

      rd: 'a; [@bits 5]
      funct3: 'a; [@bits 3]

      mem_rd: 'a; [@bits 1]
      mem_wr: 'a; [@bits 1]
      reg_wr: 'a; [@bits 1]
      branch: 'a; [@bits 1]
      jal: 'a; [@bits 1]
      jalr: 'a; [@bits 1]
      mem_to_reg : 'a; [@bits 1]

      alu_result: 'a; [@bits 32]
      rs2_data: 'a; [@bits 32]
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) =
    let spec = Reg_spec.create ~clock:i.clk ~reset:i.rst () in
    let en = ~: (i.stall) in {
      O.pc = reg spec ~enable:vdd (mux2 en i.pc (zero (width i.pc)));

      O.rd = reg spec ~enable:vdd (mux2 en i.rd (zero (width i.rd)));
      O.funct3 = reg spec ~enable:vdd (mux2 en i.funct3 (zero (width i.funct3)));

      O.mem_rd = reg spec ~enable:vdd (mux2 en i.mem_rd (zero (width i.mem_rd)));
      O.mem_wr = reg spec ~enable:vdd (mux2 en i.mem_wr (zero (width i.mem_wr)));
      O.reg_wr = reg spec ~enable:vdd (mux2 en i.reg_wr (zero (width i.reg_wr)));
      O.branch = reg spec ~enable:vdd (mux2 en i.branch (zero (width i.branch)));
      O.jal = reg spec ~enable:vdd (mux2 en i.jal (zero (width i.jal)));
      O.jalr = reg spec ~enable:vdd (mux2 en i.jalr (zero (width i.jalr)));
      O.mem_to_reg  = reg spec ~enable:vdd (mux2 en i.mem_to_reg (zero (width i.mem_to_reg)));

      O.alu_result = reg spec ~enable:vdd (mux2 en i.alu_result (zero (width i.alu_result)));
      O.rs2_data = reg spec ~enable:vdd (mux2 en i.rs2_data (zero (width i.rs2_data)));
    };

end
