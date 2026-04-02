open Hardcaml
open Signal

module Make = struct
  module I = struct
    type 'a t = {
      a: 'a; [@bits 32]
      b: 'a; [@bits 32]
      funct3: 'a; [@bits 3]
      arith: 'a; [@bits 1]
    } [@@deriving hardcaml]
  end

  module O = struct
    type 'a t = {
      result: 'a; [@bits 32]
      is_zero: 'a; [@bits 1]
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) = {
    O.result = Signal.mux i.funct3 [
      mux2 i.arith (i.a -: i.b) (i.a +: i.b);
      log_shift sll i.a (select i.b 4 0);
      uresize (i.a <: i.b) 32;
      uresize (i.a <+ i.b) 32;
      i.a ^: i.b;
      mux2 i.arith (log_shift sra i.a (select i.b 4 0)) (log_shift srl i.a (select i.b 4 0));
      i.a |: i.b;
      i.a &: i.b;
    ];
    O.is_zero = i.a ==: i.b;
  }

end
