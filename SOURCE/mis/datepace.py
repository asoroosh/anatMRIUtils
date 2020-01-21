#find the scans closesest to the 5 evenly paced milestones. 
# Example:
#ml Python 
#python3 datepace.py ses-V10x20040918  ses-V17x20060309  ses-V1jM1x20150207  ses-V27x20090228  ses-V31x20100318  ses-V6x20040515    ses-V7x20040610  ses-V9x20040819 ses-V15x20050307  ses-V19x20070308  ses-V23x20080310    ses-V2x20040304   ses-V5x20040417   ses-V778x20110217  ses-V8x20040715
# ses-V2x20040304 ses-V19x20070308 ses-V27x20090228 ses-V778x20110217 ses-V1jM1x20150207 (this is list of session we will be sending to nonlinear SST)
# ses-V10x20040417 ses-V15x20040515 ses-V17x20040610 ses-V23x20040715 ses-V31x20040819 ses-V5x20040918 ses-V6x20050307 ses-V7x20060309 ses-V8x20080310 ses-V9x20100318 (these are what we will be registrating to the SST later)
#
# PYTHON 3.6

from datetime import datetime
import numpy as np
import sys

def main():

 NumD=5

 ## Internal functions
 def days_between(d1, d2):
     d1 = datetime.strptime(d1, "%Y%m%d")
     d2 = datetime.strptime(d2, "%Y%m%d")
     return abs((d2 - d1).days)

 ## Parsing the input
 Vxtimestamps = np.array(sys.argv[1:])
 timestamps=[]
 sesaffix=[]
 for ii in Vxtimestamps: 
     timestamps.append(ii.split('x')[1])
     sesaffix.append(ii.split('x')[0])
 
 ## Do the job 
 
 V0=min(timestamps) 
 VFF=max(timestamps)
 
 sidx=sorted(range(len(timestamps)), key=lambda k: timestamps[k])

 Vxtimestamps_sorted=[] 
 timestamps = [timestamps[i] for i in sidx] 
 sesaffix = [sesaffix[i] for i in sidx]
 Vxtimestamps_sorted=[Vxtimestamps[i] for i in sidx]

 if len(Vxtimestamps_sorted)<=5:
     print(*Vxtimestamps_sorted)
     return
    

 ts_v0=np.empty(len(timestamps),dtype=int)
 for i in range(len(timestamps)): 
     ts_v0[i]=days_between(V0,timestamps[i])

 timestamps=np.asarray(timestamps,dtype=float)
 sesaffix=np.asarray(sesaffix)

 tF=np.max(ts_v0)
 msteps=np.linspace(0, tF, NumD)

 DD=np.empty([len(msteps),len(ts_v0)])
 for i in range(len(msteps)):
     for j in range(len(ts_v0)):
         DD[i,j]=abs(msteps[i]-ts_v0[j])
 
 idx_ts=np.argmin(DD,axis=1)
## send these to the SST
 ts_5dates=timestamps[idx_ts]
 sesaffix5d=sesaffix[idx_ts]

 Vx5dates=[]
 for jj in range(len(sesaffix5d)):
     Vx5dates.append(sesaffix5d[jj]+'x'+str(int(ts_5dates[jj])))

## send these to the reg2sst
 ts_no=timestamps[~np.in1d(timestamps,ts_5dates)]
 sesaffixnot=sesaffix[~np.in1d(sesaffix,sesaffix5d)]

 VxNo=[]
 for ii in range(len(sesaffixnot)):
     VxNo.append(sesaffixnot[ii]+'x'+str(int(ts_no[ii])))
 
 ## Spit out
 print(*Vx5dates)
 print(*VxNo)

 #Sanity check:
 #print('max: ' + str(VFF) +'min: ' + str(V0) + ', numebr of all visits: ' + str(len(ts_v0)))



if __name__== "__main__":
  main()
