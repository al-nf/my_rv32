open Hardcaml
open Signal

module Mux2 (Config: sig val bit_width : int end) = struct
  open Config

  module I = struct
    type 'a t = {
      in0: 'a; [@bits bit_width]
      in1: 'a; [@bits bit_width]
      sel: 'a; [@bits 1]
    } [@@deriving hardcaml]
  end

  module O = struct
    type 'a t = {
      mux_output: 'a; [@bits bit_width]
    } [@@deriving hardcaml]
  end

  let create _scope (i: _ I.t) = {
    O.mux_output = mux i.sel [i.in0; i.in1]
  }
end
