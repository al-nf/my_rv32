open Hardcaml
open Signal

module Make (Config: sig val size: int end) = struct
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
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) =
    let id_ex_mem_rd_w = wire 1 in
    let id_ex_rd_w = wire 5 in
    let mem_wb_rd_w = wire 5 in
    let mem_wb_reg_wr_w = wire 1 in
    let mem_wb_alu_result_w = wire 32 in
    let mem_wb_mem_data_w = wire 32 in
    let mem_wb_mem_to_reg_w = wire 1 in
    let pc_next_w = wire 32 in
    let stall_w = wire 1 in

    let pc_out = Pc.Make.create _scope { Pc.Make.I.
      clk = i.clk;
      rst = i.rst;

      pc_in = pc_next_w;
      pc_wr = ~:stall_w;
    } in
    let module Imem = Imem.Make(struct let size = size end) in
    let imem_out = Imem.create _scope { Imem.I.
      clk = i.clk;
      address = pc_out.pc_out;
    } in
    let if_id_out = If_id.Make.create _scope { If_id.Make.I.
      clk = i.clk;
      rst = i.rst;
      pc = pc_next_w;
      instr = imem_out.data_out;
      stall = stall_w;
    } in
    let id_out = Id.Make.create _scope { Id.Make.I.
      instr = if_id_out.instr;
    } in
    let se_out = Se.Make.create _scope { Se.Make.I.
      instr = if_id_out.instr;
    } in
    let rf_out = Rf.Make.create _scope { Rf.Make.I.
      rs1 = id_out.rs1;
      rs2 = id_out.rs2;
      rd = mem_wb_rd_w;
      clk = i.clk;
      data_in = mux2 mem_wb_mem_to_reg_w mem_wb_mem_data_w mem_wb_alu_result_w;
      reg_wr = mem_wb_reg_wr_w;
    } in
    let hdu_out = Hdu.Make.create _scope {Hdu.Make.I.
      id_ex_mem_rd = id_ex_mem_rd_w;
      id_ex_rd = id_ex_rd_w;
      if_id_rs1 = select if_id_out.instr 19 15;
      if_id_rs2 = select if_id_out.instr 24 20;
    } in
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
      mem_to_reg = id_out.mem_to_reg;

      rs1_data = rf_out.data_out1;
      rs2_data = rf_out.data_out2;
      imm = mux2 (id_out.opcode ==: of_int ~width:7 0b0100011) se_out.imm_s
               (mux2 (id_out.opcode ==: of_int ~width:7 0b1100011) se_out.imm_b
               (mux2 (id_out.opcode ==: of_int ~width:7 0b0110111) se_out.imm_u
               (mux2 (id_out.opcode ==: of_int ~width:7 0b0010111) se_out.imm_u
               (mux2 (id_out.opcode ==: of_int ~width:7 0b1101111) se_out.imm_j
               se_out.imm_i))));
      stall = stall_w;
    } in
    let alu_out = Alu.Make.create _scope { Alu.Make.I.
      a = id_ex_out.rs1_data;
      b = mux2 id_ex_out.alu_src id_ex_out.imm id_ex_out.rs2_data;
      funct3 = id_ex_out.funct3;
      arith = id_ex_out.arith;
    } in
    let ex_mem_out = Ex_mem.Make.create _scope {Ex_mem.Make.I.
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

      alu_result = alu_out.result;
      rs2_data = id_ex_out.rs2_data;

      stall = stall_w;
    } in
    let module Dmem = Dmem.Make(struct let size = size end) in
    let dmem_out = Dmem.create _scope { Dmem.I.
      clk = i.clk;
      address = ex_mem_out.alu_result;
      data_in = ex_mem_out.rs2_data;
      mem_rd = ex_mem_out.mem_rd;
      mem_wr = ex_mem_out.mem_wr;
    } in
    let mem_wb_out = Mem_wb.Make.create _scope {Mem_wb.Make.I.
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
    mem_wb_rd_w <== mem_wb_out.rd;
    mem_wb_reg_wr_w <== mem_wb_out.reg_wr;
    mem_wb_alu_result_w <== mem_wb_out.alu_result;
    mem_wb_mem_data_w <== mem_wb_out.mem_data;
    mem_wb_mem_to_reg_w <== mem_wb_out.mem_to_reg;
    pc_next_w <== pc_out.pc_out;
    stall_w <== hdu_out.stall;
    {O.pc = mem_wb_out.pc;}

end
