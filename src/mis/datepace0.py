#find the scans closesest to the 5 evenly paced milestones. 
# PYTHON 3.6

#
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


from datetime import datetime
import numpy as np
import sys

def nsmall(a, n):
# find the smallest nth element of an np array
    return np.partition(a, n)[n]

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
 timestamps0=[]
 sesaffix0=[]
 for ii in Vxtimestamps: 
     seses=ii.split('x')[0]
     ttt=ii.split('x')[1]

     if seses in ['V5','V6','V7','V8','V9']:
       timestamps0.append(ii.split('x')[1])
       sesaffix0.append(ii.split('x')[0])
     else: 
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

# print(Vxtimestamps_sorted)

 if len(timestamps)<=NumD:
     NumD=len(timestamps)
    
 ts_v0=np.empty(len(timestamps),dtype=int)
 for i in range(len(timestamps)): 
     ts_v0[i]=days_between(V0,timestamps[i])

 #print(ts_v0)

 timestamps=np.asarray(timestamps,dtype=float)
 sesaffix=np.asarray(sesaffix)

 timestamps0=np.asarray(timestamps0,dtype=float)
 sesaffix0=np.asarray(sesaffix0)


# print(timestamps)

 # idx6m = np.array(ts_v0 < 200)
 # idx6m = np.asarray(idx6m[0])
 # print(idx6m)
 #idx6m=np.where(np.array(ts_v0 < 200))[0]
 # print(idx6m)
 #aux_ses_ts = timestamps[idx6m]
 #aux_ses_id = sesaffix[idx6m]
 # print(aux_ses_ts)
 # print(aux_ses_id)
 #timestamps_cut=np.delete(timestamps,idx6m[1:])
 #sesaffix_cut=np.delete(sesaffix,idx6m[1:])
 #print(A)
 #print(B)
 #print(timestamps_cut)
 #print(sesaffix_cut)
 #ts_v0=np.empty(len(timestamps_cut),dtype=int)
 #for i in range(len(timestamps_cut)):
 #    ts_v0[i]=days_between(V0,timestamps_cut[i])
 #print(ts_v0)

# tF=np.max(ts_v0)
# msteps=np.linspace(0, tF, NumD)

# DD=np.empty([len(msteps),len(ts_v0)])
# for i in range(len(msteps)):
#     for j in range(len(ts_v0)):
#         DD[i,j]=abs(msteps[i]-ts_v0[j])
# 
# idx_ts = np.argmin(DD,axis=1)
 
# check that there are no duplicate sessions. TWO sessions might be closest to the arbitrary 
# milestones. This should be changed in the future versions to something more robust 

# print(DD)

# print(idx_ts)
# [u,c] = np.unique(idx_ts, return_counts=True)  
# if np.any(c>1): 
#     dupidx=np.where(idx_ts==u[c > 1])[0]
#     DDD=DD[dupidx[-1],:]
#     subs_idx = np.where(DD==nsmall(DDD,2))[0]
     # Now, the issue is that we might have picked an index that already exists... 
#     if np.isin(subs_idx,idx_ts):
#         subs_idx = np.where(DD==nsmall(DDD,2))[1]
         
     #print(subs_idx)     
#     idx_ts[dupidx[-1]] = subs_idx # now subsititute the new index with the previous one. 
   
## send these to the SST

# stpstp=int(np.ceil(len(timestamps)/NumD))
# print(stpstp)


 if np.size(timestamps)<NumD:

  idx_ts=np.round(np.arange(0,len(timestamps),len(timestamps)/NumD))
  idx_ts=np.asarray(idx_ts,dtype=int)

  ts_5dates=timestamps[idx_ts]
  sesaffix5d=sesaffix[idx_ts]

  Vx5dates=[]
  for jj in range(len(sesaffix5d)):
     Vx5dates.append(sesaffix5d[jj]+'x'+str(int(ts_5dates[jj])))

 else:
  ts_5dates=timestamps
  sesaffix5d=sesaffix
  Vx5dates=[]
  #print('ss')
  for jj in range(len(sesaffix5d)):
      Vx5dates.append(sesaffix5d[jj]+'x'+str(int(ts_5dates[jj]))) 

## send these to the reg2sst
 ts_no=timestamps[~np.in1d(timestamps,ts_5dates)]
 sesaffixnot=sesaffix[~np.in1d(sesaffix,sesaffix5d)]

 ts_no = np.concatenate((timestamps0,ts_no))
 sesaffixnot = np.concatenate((sesaffix0,sesaffixnot))

# print(ts_no)

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
