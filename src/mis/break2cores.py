#find the scans closesest to the 5 evenly paced milestones. 
#
# PYTHON 3.6

# Soroosh Afyouni, University of Oxford, 2020
#
#Copyright (c) 2020
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.
#

import numpy as np
import sys

def main():

 ## Parsing the input
 Vxtimestamps = np.array(sys.argv[1:-1])
 NUMCORE = np.array(sys.argv[-1],dtype=int)
#timestamps=np.asarray(timestamps,dtype=float)
 NumV = np.size(Vxtimestamps)

 PerCore=np.round(NumV/NUMCORE)
 
 for s in range(1,NUMCORE+1): 

  if s==NUMCORE:
   ONTHISCORE=Vxtimestamps[int((s-1)*PerCore):]
  else:
   ONTHISCORE=Vxtimestamps[int((s-1)*PerCore):int(s*PerCore)]
  print(*ONTHISCORE)

if __name__== "__main__":
  main()
