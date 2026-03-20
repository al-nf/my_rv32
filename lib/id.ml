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
      funct7: 'a; [@bits 7]
      opcode: 'a; [@bits 7]

      mem_rd: 'a; [@bits 1]
      mem_wr: 'a; [@bits 1]
      reg_wr: 'a; [@bits 1]
      branch: 'a; [@bits 1]
      jal: 'a; [@bits 1]
      jalr: 'a; [@bits 1]
      alu_op: 'a; [@bits 4] (* will decide this later *)
      alu_src: 'a; [@bits 1]
      mem_to_reg : 'a; [@bits 1]
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) =
    let opcode = select i.instr 6 0 in
    let is op = opcode ==: of_int ~width:7 op in
    {
      O.rs1 = select i.instr 19 15;
      O.rs2 = select i.instr 24 20;
      O.rd = select i.instr 11 7;
      O.funct3 = select i.instr 14 12;
      O.funct7 = select i.instr 31 25;
      O.opcode = opcode;
      O.mem_rd = is 0b0000011;
      O.mem_wr = is 0b0100011;
      O.reg_wr = (is 0b0110011) |: (is 0b0010011) |: (is 0b0000011) |: (is 0b1101111) |: (is 0b1100111);
      O.branch = is 0b1100011;
      O.jal = is 0b1101111;
      O.jalr = is 0b1100111;
      O.alu_op = of_int ~width:4 0b0000; (* CHANGE THIS DURING ALU DESIGN *)
      O.alu_src = ~: (is 0b0110011);
      O.mem_to_reg = is 0b0000011;
    }
end
