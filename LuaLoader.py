# Start FCEUX and load a lua script

## Imports
from multiprocessing.pool import Pool
import subprocess
from datetime import datetime
import os
import shutil
import json
import matplotlib.pyplot as plt
import numpy as np

EMU = r".\fceux-2.6.6-win64\fceux64.exe"
ROM = r".\ROMS\Galaga\Galaga.nes"
SCRIPT = r"D:\Programming\Github\NES_Nets\lua\test_script.lua"
DIR = "D:\\Programming\\Github\\NES_Nets\\"

class EMU_Process():
  def __init__(self, name, input):
    self.emu = EMU
    self.rom = ROM
    self.script = SCRIPT
    self.input = input
    self.name = name

  def run(self):
    # Start emulator on a subprocess
    arg = self.emu + ' -lua ' + self.script + ' ' + self.rom
    input_json = json.dumps(self.input)
    self.proc = subprocess.run(arg, input=input_json, capture_output=True, encoding="utf-8")

    # Get output from stdout
    ## remove weird junk from start of stdout
    output = self.proc.stdout[self.proc.stdout.index("\n")+1:] 
    
    # Convert output to dict
    try:
      output = json.loads(output)
    except:
      # Most likely empty string as output; return empty dict
      output = dict()

    return output
  
  @staticmethod
  def create_and_run(args):
    '''
    Used for process pool execution
    '''
    name, input = args
    proc = EMU_Process(name, input)
    return (name, proc.run())

def run_agents(N, name_base=""):
  names = ["{}_{}".format(name_base, i) for i in range(1, N+1)]
  pool = Pool(N)
  args = [(n, {"name": n}) for n in names]
  res = pool.map_async(EMU_Process.create_and_run, args)
  final = res.get()
  del pool
  return final
  
def time_runs(max=20):
  Ns = list(range(1, max+1))
  deltas = []
  for N in Ns:
    start_time = datetime.now()
    run_agents(N)
    end_time = datetime.now()
    deltas.append((end_time-start_time).seconds)

  plt.plot(Ns, deltas)
  plt.show()


def main():
  ## Code
  print("PYTHON SCRIPT START\n")

  print(run_agents(1, "Agent"))
  
  print("\nPYTHON SCRIPT END")

if __name__ == "__main__":
  main()