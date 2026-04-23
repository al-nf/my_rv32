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
      arith: 'a; [@bits 1]      (* bit 30 of instr, only valid when the op actually uses it *)
      alu_src: 'a; [@bits 1]    (* 0 -> rs2_data, 1 -> imm *)
      alu_a_sel: 'a; [@bits 2]  (* 00 rs1, 01 pc (AUIPC), 10 zero (LUI), 11 unused *)
      link: 'a; [@bits 1]       (* write pc+4 to rd (JAL/JALR) *)
      mem_to_reg: 'a; [@bits 1]
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) =
    let opcode = select i.instr 6 0 in
    let funct3 = select i.instr 14 12 in
    let is op = opcode ==:. op in
    let is_r_type = is 0b0110011 in
    let is_i_alu = is 0b0010011 in
    let is_load = is 0b0000011 in
    let is_store = is 0b0100011 in
    let is_branch = is 0b1100011 in
    let is_jal = is 0b1101111 in
    let is_jalr = is 0b1100111 in
    let is_lui = is 0b0110111 in
    let is_auipc = is 0b0010111 in
    let is_shift_imm = is_i_alu &: (funct3 ==:. 0b101) in
    {
      O.rs1 = select i.instr 19 15;
      O.rs2 = select i.instr 24 20;
      O.rd = select i.instr 11 7;
      O.funct3 = funct3;
      O.opcode = opcode;
      O.mem_rd = is_load;
      O.mem_wr = is_store;
      O.reg_wr =
        is_r_type |: is_i_alu |: is_load |: is_jal |: is_jalr |: is_lui |: is_auipc;
      O.branch = is_branch;
      O.jal = is_jal;
      O.jalr = is_jalr;
      (* instr[30] only actually encodes ADD/SUB or SRL/SRA; for everything else it's
         an immediate bit that must not leak into the ALU control. *)
      O.arith = (select i.instr 30 30) &: (is_r_type |: is_shift_imm);
      (* R-type reads rs2; everything else that uses the ALU uses an immediate. *)
      O.alu_src = ~: is_r_type;
      O.alu_a_sel =
        mux2 is_lui (of_int ~width:2 0b10)
       (mux2 is_auipc (of_int ~width:2 0b01)
                      (of_int ~width:2 0b00));
      O.link = is_jal |: is_jalr;
      O.mem_to_reg = is_load;
    }
end
