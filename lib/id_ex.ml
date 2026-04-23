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
      arith: 'a; [@bits 1]
      alu_src: 'a; [@bits 1]
      alu_a_sel: 'a; [@bits 2]
      alu_funct3: 'a; [@bits 3]
      link: 'a; [@bits 1]
      mem_to_reg: 'a; [@bits 1]
      rs1_data: 'a; [@bits 32]
      rs2_data: 'a; [@bits 32]
      imm: 'a; [@bits 32]
      stall: 'a; [@bits 1]
      flush: 'a; [@bits 1]
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
      arith: 'a; [@bits 1]
      alu_src: 'a; [@bits 1]
      alu_a_sel: 'a; [@bits 2]
      alu_funct3: 'a; [@bits 3]
      link: 'a; [@bits 1]
      mem_to_reg: 'a; [@bits 1]
      rs1_data: 'a; [@bits 32]
      rs2_data: 'a; [@bits 32]
      imm: 'a; [@bits 32]
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) =
    let spec = Reg_spec.create ~clock:i.clk ~reset:i.rst () in
    let clear = i.stall |: i.flush in
    let sel x = mux2 clear (zero (width x)) x in
    {
      O.pc = reg spec (sel i.pc);
      O.rs1 = reg spec (sel i.rs1);
      O.rs2 = reg spec (sel i.rs2);
      O.rd = reg spec (sel i.rd);
      O.funct3 = reg spec (sel i.funct3);
      O.mem_rd = reg spec (sel i.mem_rd);
      O.mem_wr = reg spec (sel i.mem_wr);
      O.reg_wr = reg spec (sel i.reg_wr);
      O.branch = reg spec (sel i.branch);
      O.jal = reg spec (sel i.jal);
      O.jalr = reg spec (sel i.jalr);
      O.arith = reg spec (sel i.arith);
      O.alu_src = reg spec (sel i.alu_src);
      O.alu_a_sel = reg spec (sel i.alu_a_sel);
      O.alu_funct3 = reg spec (sel i.alu_funct3);
      O.link = reg spec (sel i.link);
      O.mem_to_reg = reg spec (sel i.mem_to_reg);
      O.rs1_data = reg spec (sel i.rs1_data);
      O.rs2_data = reg spec (sel i.rs2_data);
      O.imm = reg spec (sel i.imm);
    }
end
