# Start FCEUX and load a lua script

## Imports
from multiprocessing.pool import Pool
import subprocess
import threading
from queue import Queue
import time
from datetime import datetime
import matplotlib.pyplot as plt
import numpy as np
import os
import shutil

EMU = r"D:\Programs\Emulators\fceux-2.6.6-win64\fceux64.exe"
ROM = r"D:\Programs\Emulators\ROMS\Galaga\Galaga.nes"
SCRIPT = r"D:\Programming\Github\NES_Nets\lua\test_script.lua"
DIR = "D:\\Programming\\Github\\NES_Nets\\"

class EMU_Process():
  def __init__(self, name="process/"):
    self.emu = EMU
    self.rom = ROM
    self.base_script = SCRIPT
    self.name = name

  def init_files(self, script_input=""):
     #Create files
    if os.path.exists(self.name): #Delete directory if it already exists
      shutil.rmtree(self.name)

    os.mkdir(self.name)
    input_filename = "{}/input".format(self.name)
    self.input_file = open(input_filename, 'w')
    self.input_file.write(script_input)
    self.input_file.close()

    #
    self.run_script = DIR + "{}/script.lua".format(self.name)
    shutil.copyfile(self.base_script, self.run_script)

  def run(self):
    # Start emulator on a subprocess
    arg = self.emu + ' -lua ' + self.run_script + ' ' + self.rom
    self.proc = subprocess.run(arg, capture_output=True)

    # Get output from stdout, append to queue
    output = str(self.proc.stdout)
    return (self.name, output)
  
  @staticmethod
  def create_and_run(args):
    name, script_input = args
    proc = EMU_Process(name)
    proc.init_files(script_input)
    return proc.run()


def run_agents(N, name_base=""):
  names = ["output/Agent{}_{}/".format(name_base, i) for i in range(1, N+1)]
  pool = Pool(N)
  res = pool.map_async(EMU_Process.create_and_run, [(n, n) for n in names])
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

  print(run_agents(1))
  
  print("\nPYTHON SCRIPT END")

if __name__ == "__main__":
  main()