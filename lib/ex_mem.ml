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
      O.pc = reg spec ~enable:vdd (i.pc &: en);

      O.rd = reg spec ~enable:vdd (i.rd &: en);
      O.funct3 = reg spec ~enable:vdd (i.funct3 &: en);

      O.mem_rd = reg spec ~enable:vdd (i.mem_rd &: en);
      O.mem_wr = reg spec ~enable:vdd (i.mem_wr &: en);
      O.reg_wr = reg spec ~enable:vdd (i.reg_wr &: en);
      O.branch = reg spec ~enable:vdd (i.branch &: en);
      O.jal = reg spec ~enable:vdd (i.jal &: en);
      O.jalr = reg spec ~enable:vdd (i.jalr &: en);
      O.mem_to_reg  = reg spec ~enable:vdd (i.mem_to_reg &: en);

      O.alu_result = reg spec ~enable:vdd (i.alu_result &: en);
      O.rs2_data = reg spec ~enable:vdd (i.rs2_data &: en);
    };

end
