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
      mem_to_reg: 'a; [@bits 1]
      alu_result: 'a; [@bits 32]
      rs2_data: 'a; [@bits 32]
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
      mem_to_reg: 'a; [@bits 1]
      alu_result: 'a; [@bits 32]
      rs2_data: 'a; [@bits 32]
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) =
    let spec = Reg_spec.create ~clock:i.clk ~reset:i.rst () in
    {
      O.pc = reg spec i.pc;
      O.rd = reg spec i.rd;
      O.funct3 = reg spec i.funct3;
      O.mem_rd = reg spec i.mem_rd;
      O.mem_wr = reg spec i.mem_wr;
      O.reg_wr = reg spec i.reg_wr;
      O.branch = reg spec i.branch;
      O.jal = reg spec i.jal;
      O.jalr = reg spec i.jalr;
      O.mem_to_reg = reg spec i.mem_to_reg;
      O.alu_result = reg spec i.alu_result;
      O.rs2_data = reg spec i.rs2_data;
    }
end
