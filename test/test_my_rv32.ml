open Hardcaml
open My_rv32

module Top_inst = Top.Make(struct let size = 4294967296 end)
module Sim = Hardcaml.Cyclesim.With_interface(Top_inst.I)(Top_inst.O)

let () =
  let scope = Hardcaml.Scope.create () in
  let sim = Sim.create (Top_inst.create scope) in
  let waves, sim = Hardcaml_waveterm.Waveform.create sim in

  let inputs = Cyclesim.inputs sim in
  inputs.rst := Bits.vdd;
  Cyclesim.cycle sim;
  inputs.rst := Bits.gnd;

  for _ = 0 to 20 do
    Cyclesim.cycle sim
  done;

  Hardcaml_waveterm.Waveform.print waves
