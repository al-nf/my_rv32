open Hardcaml
open Signal

module Make (Config: sig
  val size: int
  val program_file: string
end) = struct
  open Config
  module I = struct
    type 'a t = {
      clk: 'a [@bits 1];
      address: 'a [@bits 32];
    } [@@deriving hardcaml]
  end

  module O = struct
    type 'a t = {
      data_out: 'a [@bits 32];
    } [@@deriving hardcaml]
  end

  (* Read the program once at elaboration time.  We pad short programs with
     NOPs so the mux domain equals [size]. *)
  let load_program () =
    let ic = open_in program_file in
    let acc = ref [] in
    (try
       while true do
         let line = String.trim (input_line ic) in
         if line <> "" then acc := line :: !acc
       done
     with End_of_file -> ());
    close_in ic;
    let words = List.rev !acc in
    let nop = "00000013" in
    let padded =
      if List.length words >= size then words
      else words @ List.init (size - List.length words) (fun _ -> nop)
    in
    Array.of_list (List.map (fun w -> Hardcaml.Signal.of_string ("32'h" ^ w)) padded)

  let create _scope (i: _ I.t) =
    let program = load_program () in
    let word_address = select i.address 31 2 in
    { O.data_out = mux word_address (Array.to_list program) }
end
