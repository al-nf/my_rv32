open Hardcaml
open Signal

module Make (Config: sig
  val isize: int
  val dsize: int
  val program_file: string
end) = struct
  open Config
  module I = struct
    type 'a t = {
      clk: 'a [@bits 1];
      rst: 'a [@bits 1];
    } [@@deriving hardcaml]
  end

  module O = struct
    type 'a t = {
      pc: 'a [@bits 32];
      branch_target_w: 'a [@bits 32];
      actual_taken_w: 'a [@bits 1];
      wb_rd: 'a [@bits 5];
      wb_data: 'a [@bits 32];
      wb_reg_wr: 'a [@bits 1];
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) =
    let id_ex_mem_rd_w = wire 1 in
    let id_ex_rd_w = wire 5 in
    let ex_mem_rd_w = wire 5 in
    let ex_mem_reg_wr_w = wire 1 in
    let ex_mem_alu_result_w = wire 32 in
    let mem_wb_rd_w = wire 5 in
    let mem_wb_reg_wr_w = wire 1 in
    let mem_wb_alu_result_w = wire 32 in
    let mem_wb_mem_data_w = wire 32 in
    let mem_wb_mem_to_reg_w = wire 1 in
    let actual_taken_w = wire 1 in
    let branch_target_w = wire 32 in
    let stall_w = wire 1 in
    let flush_w = wire 1 in

    let pc_out = Pc.Make.create _scope { Pc.Make.I.
      clk = i.clk;
      rst = i.rst;
      pc_in = branch_target_w;
      pc_wr = actual_taken_w;
      stall = stall_w;
    } in

    let module Imem = Imem.Make(struct
      let size = isize
      let program_file = program_file
    end) in
    let imem_out = Imem.create _scope { Imem.I.
      clk = i.clk;
      address = pc_out.pc_out;
    } in

    let if_id_out = If_id.Make.create _scope { If_id.Make.I.
      clk = i.clk;
      rst = i.rst;
      pc = pc_out.pc_out;
      instr = imem_out.data_out;
      stall = stall_w;
      flush = flush_w;
    } in

    let id_out = Id.Make.create _scope { Id.Make.I.
      instr = if_id_out.instr;
    } in

    let se_out = Se.Make.create _scope { Se.Make.I.
      instr = if_id_out.instr;
    } in

    let wb_data =
      mux2 mem_wb_mem_to_reg_w mem_wb_mem_data_w mem_wb_alu_result_w
    in

    let rf_out = Rf.Make.create _scope { Rf.Make.I.
      rs1 = id_out.rs1;
      rs2 = id_out.rs2;
      rd = mem_wb_rd_w;
      clk = i.clk;
      data_in = wb_data;
      reg_wr = mem_wb_reg_wr_w;
    } in

    let hdu_out = Hdu.Make.create _scope { Hdu.Make.I.
      id_ex_mem_rd = id_ex_mem_rd_w;
      id_ex_rd = id_ex_rd_w;
      if_id_rs1 = select if_id_out.instr 19 15;
      if_id_rs2 = select if_id_out.instr 24 20;
    } in

    let imm_sel =
      mux2 (id_out.opcode ==:. 0b0100011) se_out.imm_s
      (mux2 (id_out.opcode ==:. 0b1100011) se_out.imm_b
        (mux2 (id_out.opcode ==:. 0b0110111) se_out.imm_u
          (mux2 (id_out.opcode ==:. 0b0010111) se_out.imm_u
            (mux2 (id_out.opcode ==:. 0b1101111) se_out.imm_j
              se_out.imm_i))))
    in

    let id_ex_out = Id_ex.Make.create _scope { Id_ex.Make.I.
      clk = i.clk;
      rst = i.rst;
      pc = if_id_out.pc;
      rs1 = id_out.rs1;
      rs2 = id_out.rs2;
      rd = id_out.rd;
      funct3 = id_out.funct3;
      opcode = id_out.opcode;
      mem_rd = id_out.mem_rd;
      mem_wr = id_out.mem_wr;
      reg_wr = id_out.reg_wr;
      branch = id_out.branch;
      jal = id_out.jal;
      jalr = id_out.jalr;
      arith = id_out.arith;
      alu_src = id_out.alu_src;
      alu_a_sel = id_out.alu_a_sel;
      alu_funct3 = id_out.alu_funct3;
      link = id_out.link;
      mem_to_reg = id_out.mem_to_reg;
      rs1_data = rf_out.data_out1;
      rs2_data = rf_out.data_out2;
      imm = imm_sel;
      stall = stall_w;
      flush = flush_w;
    } in

    let fwd_out = Fwd.Make.create _scope { Fwd.Make.I.
      ex_mem_rd = ex_mem_rd_w;
      ex_mem_reg_wr = ex_mem_reg_wr_w;
      mem_wb_rd = mem_wb_rd_w;
      mem_wb_reg_wr = mem_wb_reg_wr_w;
      id_ex_rs1 = id_ex_out.rs1;
      id_ex_rs2 = id_ex_out.rs2;
    } in
    let forward sel reg_val =
      mux sel [
        reg_val;
        wb_data;
        ex_mem_alu_result_w;
        reg_val;
      ]
    in
    let rs1_fwd = forward fwd_out.forward_a id_ex_out.rs1_data in
    let rs2_fwd = forward fwd_out.forward_b id_ex_out.rs2_data in

    let alu_a =
      mux id_ex_out.alu_a_sel [
        rs1_fwd;
        id_ex_out.pc;
        zero 32;
        zero 32;
      ]
    in
    let alu_b = mux2 id_ex_out.alu_src id_ex_out.imm rs2_fwd in

    let alu_out = Alu.Make.create _scope { Alu.Make.I.
      a = alu_a;
      b = alu_b;
      funct3 = id_ex_out.alu_funct3;
      arith = id_ex_out.arith;
    } in

    let branch_cmp_out = Branch_cmp.Make.create _scope { Branch_cmp.Make.I.
      rs1_data = rs1_fwd;
      rs2_data = rs2_fwd;
      funct3 = id_ex_out.funct3;
    } in

    let actual_taken =
      (id_ex_out.branch &: branch_cmp_out.taken)
      |: id_ex_out.jal
      |: id_ex_out.jalr in
    let branch_target =
      let jalr_target = (rs1_fwd +: id_ex_out.imm) &: (ones 32 -:. 1) in
      mux2 id_ex_out.jalr
        jalr_target
        (id_ex_out.pc +: id_ex_out.imm)
    in

    actual_taken_w <== actual_taken;
    branch_target_w <== branch_target;
    flush_w <== actual_taken;

    let link_value = id_ex_out.pc +:. 4 in
    let result_to_mem = mux2 id_ex_out.link link_value alu_out.result in

    let ex_mem_out = Ex_mem.Make.create _scope { Ex_mem.Make.I.
      clk = i.clk;
      rst = i.rst;
      pc = id_ex_out.pc;
      rd = id_ex_out.rd;
      funct3 = id_ex_out.funct3;
      mem_rd = id_ex_out.mem_rd;
      mem_wr = id_ex_out.mem_wr;
      reg_wr = id_ex_out.reg_wr;
      branch = id_ex_out.branch;
      jal = id_ex_out.jal;
      jalr = id_ex_out.jalr;
      mem_to_reg = id_ex_out.mem_to_reg;
      alu_result = result_to_mem;
      rs2_data = rs2_fwd;
    } in

    let module Dmem = Dmem.Make(struct let size = dsize end) in
    let dmem_out = Dmem.create _scope { Dmem.I.
      clk = i.clk;
      address = ex_mem_out.alu_result;
      data_in = ex_mem_out.rs2_data;
      mem_rd = ex_mem_out.mem_rd;
      mem_wr = ex_mem_out.mem_wr;
    } in

    let mem_wb_out = Mem_wb.Make.create _scope { Mem_wb.Make.I.
      clk = i.clk;
      rst = i.rst;
      pc = ex_mem_out.pc;
      rd = ex_mem_out.rd;
      reg_wr = ex_mem_out.reg_wr;
      mem_to_reg = ex_mem_out.mem_to_reg;
      alu_result = ex_mem_out.alu_result;
      mem_data = dmem_out.data_out;
    } in

    id_ex_mem_rd_w <== id_ex_out.mem_rd;
    id_ex_rd_w <== id_ex_out.rd;
    ex_mem_rd_w <== ex_mem_out.rd;
    ex_mem_reg_wr_w <== ex_mem_out.reg_wr;
    ex_mem_alu_result_w <== ex_mem_out.alu_result;
    mem_wb_rd_w <== mem_wb_out.rd;
    mem_wb_reg_wr_w <== mem_wb_out.reg_wr;
    mem_wb_alu_result_w <== mem_wb_out.alu_result;
    mem_wb_mem_data_w <== mem_wb_out.mem_data;
    mem_wb_mem_to_reg_w <== mem_wb_out.mem_to_reg;
    stall_w <== hdu_out.stall;

    {
      O.pc = mem_wb_out.pc;
      O.branch_target_w = branch_target_w;
      O.actual_taken_w = actual_taken_w;
      O.wb_rd = mem_wb_out.rd;
      O.wb_data = wb_data;
      O.wb_reg_wr = mem_wb_out.reg_wr &: (mem_wb_out.rd <>: zero 5);
    }

end
