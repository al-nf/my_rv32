open Hardcaml
open My_rv32

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
  max 1 !n

let run ~label ~program_file ~cycles ~expected =
  let module T = Top.Make(struct
    let isize = count_lines program_file
    let dsize = 1024
    let program_file = program_file
  end) in
  let module Sim = Hardcaml.Cyclesim.With_interface(T.I)(T.O) in
  let scope = Hardcaml.Scope.create () in
  let sim = Sim.create (T.create scope) in
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in
  inputs.rst := Bits.vdd;
  Cyclesim.cycle sim;
  inputs.rst := Bits.gnd;
  let regs = Array.make 32 0 in
  for _ = 1 to cycles do
    Cyclesim.cycle sim;
    if Bits.to_int !(outputs.wb_reg_wr) = 1 then begin
      let rd = Bits.to_int !(outputs.wb_rd) in
      let data = Bits.to_int !(outputs.wb_data) in
      regs.(rd) <- data
    end
  done;
  Printf.printf "\n";
  let ok = ref true in
  List.iter (fun (r, want) ->
    let got = regs.(r) in
    if got <> want then begin
      Printf.printf "[%s] FAIL x%d: got 0x%08x, expected 0x%08x\n"
        label r got want;
      ok := false
    end) expected;
  if !ok then Printf.printf "[%s] PASS\n" label

let () =
  (* Baseline: two BEQs that both fall through to the target. *)
  run ~label:"beq"
      ~program_file:"program.hex"
      ~cycles:50
      ~expected:[
        1, 0;  (* addi x1, x0, 0 *)
        2, 0;  (* addi x2, x0, 0 *)
        3, 0;  (* flushed after taken beq *)
        4, 7;  (* addi x4, x0, 7 *)
        5, 0;  (* flushed after taken beq *)
      ];

  (* Signed comparison: exercises <+ vs <: in branch_cmp. *)
  run ~label:"blt-signed"
      ~program_file:"program_blt.hex"
      ~cycles:50
      ~expected:[
        1, 0xFFFFFFFF; (* x1 = -1 *)
        2, 1;
        3, 0;          (* skipped if BLT is signed: -1 < 1 is true *)
        4, 7;
      ];

  (* Forwarding: each addi depends on its predecessor. *)
  run ~label:"forward"
      ~program_file:"program_fwd.hex"
      ~cycles:50
      ~expected:[
        1, 5;
        2, 8;  (* 5 + 3, needs x1 forwarded from EX/MEM *)
        3, 9;  (* 8 + 1, needs x2 forwarded from EX/MEM *)
      ]
