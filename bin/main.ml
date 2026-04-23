open My_rv32

let default_program = "program.hex"

let program_path () =
  if Array.length Sys.argv >= 2 then Sys.argv.(1) else default_program

let count_lines path =
  let ic = open_in path in
  let n = ref 0 in
  (try
     while true do
       let line = String.trim (input_line ic) in
       if line <> "" then incr n
     done
   with End_of_file -> ());
  close_in ic;
  !n

let () =
  let path = program_path () in
  let size = max 1 (count_lines path) in
  let module Top = Top.Make(struct
    let isize = size
    let dsize = 1024
    let program_file = path
  end) in
  let module Circuit = Hardcaml.Circuit.With_interface(Top.I)(Top.O) in
  let scope = Hardcaml.Scope.create ~flatten_design:true () in
  let circuit = Circuit.create_exn ~name:"top" (Top.create scope) in
  Hardcaml.Rtl.print Verilog circuit
