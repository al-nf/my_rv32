open Hardcaml
open Signal

module Make (Config: sig val size: int end) = struct
  open Config
  module I = struct
    type 'a t = {
      clk: 'a [@bits 1];
      address: 'a [@bits 32];
      data_in: 'a [@bits 32];
      mem_rd: 'a [@bits 1];
      mem_wr: 'a [@bits 1];
    } [@@deriving hardcaml]
  end

  module O = struct
    type 'a t = {
      data_out: 'a [@bits 32];
    } [@@deriving hardcaml]
  end

  (* We want combinational reads so a load completes in one MEM cycle; the
     MEM/WB register then captures the value for WB.  multiport_memory only
     offers registered reads, so we roll our own array of word-wide
     registers with a one-hot write enable and a combinational mux read. *)
  let create _scope (i: _ I.t) =
    let _ = i.mem_rd in
    let spec = Reg_spec.create ~clock:i.clk () in
    let addr = select i.address 11 2 in
    let cells =
      Array.init size (fun idx ->
        let hit = addr ==:. idx in
        let en  = i.mem_wr &: hit in
        reg_fb spec ~enable:en ~width:32 ~f:(fun _ -> i.data_in))
    in
    { O.data_out = mux addr (Array.to_list cells) }
end
