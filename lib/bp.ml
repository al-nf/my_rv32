open Hardcaml
open Signal

module Make = struct
  module I = struct
    type 'a t = {
      clk: 'a [@bits 1];
      rst: 'a [@bits 1];
      taken: 'a [@bits 1];
    } [@@deriving hardcaml]
  end

  module O = struct
    type 'a t = {
      predict: 'a [@bits 1];
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) =
    let spec = Reg_spec.create ~clock:i.clk ~reset:i.rst () in
    let counter = reg_fb spec ~enable:vdd ~width:2 ~f:( fun c ->
      mux2 i.taken (
        mux2 (c ==:. 3)
          (c)
          (c +:. 1)
      )
      (
        mux2 (c ==:. 0)
          (c)
          (c -:. 1)
      )
    ) in { O.predict = select counter 1 1 }

end
