# find the scans closes to the timeline seperated every 5 years. 
#timestamps=np.array(['20110602','20110805','20110204','20101202','20111130','20101126','20101123','20101122','20101116'])
#ses-V10x20041002  ses-V2x20040328  ses-V5x20040430  ses-V6x20040605  ses-V7x20040711  ses-V8x20040812  ses-V9x20040905

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
 ts_5dates=timestamps[idx_ts]
 sesaffix5d=sesaffix[idx_ts]

 sesaffixnot=np.setdiff1d(sesaffix,sesaffix5d)
 ts_no=np.setdiff1d(timestamps,ts_5dates)
 
 VxNo=[]
 for ii in range(len(sesaffixnot)):
     VxNo.append(sesaffixnot[ii]+'x'+str(int(ts_no[ii])))

 Vx5dates=[]
 for jj in range(len(sesaffix5d)):
     Vx5dates.append(sesaffix5d[jj]+'x'+str(int(ts_5dates[jj])))
 
 ## Spit out
 print(*Vx5dates)
 print(*VxNo)

 #Sanity check:
 #print('max: ' + str(VFF) +'min: ' + str(V0) + ', numebr of all visits: ' + str(len(ts_v0)))



if __name__== "__main__":
  main()
