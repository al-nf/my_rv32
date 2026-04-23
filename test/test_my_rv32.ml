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
  run ~label:"beq"
      ~program_file:"program_beq.hex"
      ~cycles:50
      ~expected:[
        1, 0;
        2, 0;
        3, 0;
        4, 7;
        5, 0;
      ];

  run ~label:"blt-signed"
      ~program_file:"program_blt.hex"
      ~cycles:50
      ~expected:[
        1, 0xFFFFFFFF;
        2, 1;
        3, 0;
        4, 7;
      ];

  run ~label:"forward"
      ~program_file:"program_fwd.hex"
      ~cycles:50
      ~expected:[
        1, 5;
        2, 8;
        3, 9;
      ];

  run ~label:"ls"
      ~program_file:"program_ls.hex"
      ~cycles:50
      ~expected:[
        1, 7;
        2, 7;
        3, 8;
      ];

  run ~label:"ls-offset"
      ~program_file:"program_ls_off.hex"
      ~cycles:50
      ~expected:[
        1, 42;
        2, 42;
        3, 43;
      ];

  run ~label:"alu"
      ~program_file:"program_alu.hex"
      ~cycles:60
      ~expected:[
        1,  5;
        2,  0xFFFFFFFE;
        3,  7;
        4,  0xA0; 
        5,  0x07FFFFFF;
        6,  0xFFFFFFFF;
        7,  0xFFFFFFFB;
        8,  0xFFFFFFFF;
        9,  4;
        10, 1;
      ];

  run ~label:"lui-auipc"
      ~program_file:"program_lui.hex"
      ~cycles:50
      ~expected:[
        1, 0x12345000;
        2, 0x00000004; 
        3, 0x00001008;
      ];

  run ~label:"jump"
      ~program_file:"program_jump.hex"
      ~cycles:50
      ~expected:[
        1,  0x04;
        2,  0x10;
        3,  0x04;
        4,  0x10;
        6,  20;
        10, 0;
        11, 0;
      ]