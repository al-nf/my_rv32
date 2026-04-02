open Hardcaml
open Signal

module Make = struct
  module I = struct
    type 'a t = {
      clk: 'a [@bits 1];
      rst: 'a [@bits 1];

      pc: 'a [@bits 32];

      rs1: 'a; [@bits 5]
      rs2: 'a; [@bits 5]
      rd: 'a; [@bits 5]
      funct3: 'a; [@bits 3]
      opcode: 'a; [@bits 7]

      mem_rd: 'a; [@bits 1]
      mem_wr: 'a; [@bits 1]
      reg_wr: 'a; [@bits 1]
      branch: 'a; [@bits 1]
      jal: 'a; [@bits 1]
      jalr: 'a; [@bits 1]
      arith: 'a; [@bits 1] (* 0 for add/srl, 1 for sub/sra *)
      alu_src: 'a; [@bits 1]
      mem_to_reg : 'a; [@bits 1]

      rs1_data: 'a; [@bits 32]
      rs2_data: 'a; [@bits 32]
      imm: 'a; [@bits 32]

      stall: 'a; [@bits 1]
    } [@@deriving hardcaml]

  end

  module O = struct
    type 'a t = {
      pc: 'a [@bits 32];

      rs1: 'a; [@bits 5]
      rs2: 'a; [@bits 5]
      rd: 'a; [@bits 5]
      funct3: 'a; [@bits 3]

      mem_rd: 'a; [@bits 1]
      mem_wr: 'a; [@bits 1]
      reg_wr: 'a; [@bits 1]
      branch: 'a; [@bits 1]
      jal: 'a; [@bits 1]
      jalr: 'a; [@bits 1]
      arith: 'a; [@bits 1] (* 0 for add/srl, 1 for sub/sra *)
      alu_src: 'a; [@bits 1]
      mem_to_reg : 'a; [@bits 1]

      rs1_data: 'a; [@bits 32]
      rs2_data: 'a; [@bits 32]
      imm: 'a; [@bits 32]
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) =
    let spec = Reg_spec.create ~clock:i.clk ~reset:i.rst () in
    let en = ~: (i.stall) in {
      O.pc = reg spec ~enable:vdd (mux2 en i.pc (zero (width i.pc)));
      O.rs1 = reg spec ~enable:vdd (mux2 en i.rs1 (zero (width i.rs1)));
      O.rs2 = reg spec ~enable:vdd (mux2 en i.rs2 (zero (width i.rs2)));
      O.rd = reg spec ~enable:vdd (mux2 en i.rd (zero (width i.rd)));
      O.funct3 = reg spec ~enable:vdd (mux2 en i.funct3 (zero (width i.funct3)));
      O.mem_rd = reg spec ~enable:vdd (mux2 en i.mem_rd (zero (width i.mem_rd)));
      O.mem_wr = reg spec ~enable:vdd (mux2 en i.mem_wr (zero (width i.mem_wr)));
      O.reg_wr = reg spec ~enable:vdd (mux2 en i.reg_wr (zero (width i.reg_wr)));
      O.branch = reg spec ~enable:vdd (mux2 en i.branch (zero (width i.branch)));
      O.jal = reg spec ~enable:vdd (mux2 en i.jal (zero (width i.jal)));
      O.jalr = reg spec ~enable:vdd (mux2 en i.jalr (zero (width i.jalr)));
      O.arith = reg spec ~enable:vdd (mux2 en i.arith (zero (width i.arith)));
      O.alu_src = reg spec ~enable:vdd (mux2 en i.alu_src (zero (width i.alu_src)));
      O.mem_to_reg = reg spec ~enable:vdd (mux2 en i.mem_to_reg (zero (width i.mem_to_reg)));
      O.rs1_data = reg spec ~enable:vdd (mux2 en i.rs1_data (zero (width i.rs1_data)));
      O.rs2_data = reg spec ~enable:vdd (mux2 en i.rs2_data (zero (width i.rs2_data)));
      O.imm = reg spec ~enable:vdd (mux2 en i.imm (zero (width i.imm)));
    };

end
