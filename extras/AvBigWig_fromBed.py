# -*- coding: utf-8 -*-
"""
@author: Ahrmad
"""

import numpy as np
from operator import add
from scipy.ndimage import uniform_filter1d

#Variables to adapt to the region of interest (~1500 positions/min)
chromStart = 4980000
chromEnd = 5040000
chrom = 'chrIII'


startFile = "Start.txt"
posFile = 'Met.txt'

#load start positions of reads as list
startPos = list(np.genfromtxt(startFile,dtype='uint32',delimiter='\t',skip_header=0))

#load positions of methylation as a list of list (reads)
met = []
with open(posFile) as f:
	lines=f.readlines()
	for line in lines:
		m = line.rstrip('\n').split(",")
		m = [int(i) for i in m]
		met.append(m)

# add the start position to the read positions
metS = list(map(add, met, startPos))

# make a list of list containing all positions in the read
readpos = [list(range(one[0]+1, one[-1], 1)) for one in metS]


#Create empty final array
#1st column is pos, 
#2nd column is number of methyl at this position, 
#3rd column is total number of read coevering that region

fin = np.array(list(range(chromStart, chromEnd+1, 1)))
sc = np.zeros(fin.shape)
fin = np.column_stack((fin, sc, sc))

#Fill the array above
size = chromEnd - chromStart
for a,Regionpos in enumerate(range(chromStart, chromEnd+1,1)):
	prog = (Regionpos - (chromStart - 1)) / size
	print(f'{prog:.1%}', end='\r')
	for i,read in enumerate(readpos):
		if Regionpos in read:
			if Regionpos in metS[i]:
				fin[a][1] = fin[a][1] + 1
				fin[a][2] = fin[a][2] + 1
			else:
				fin[a][2] = fin[a][2] + 1

# get 1 - Fraction methylated
fin[:,1] = 1 - (fin[:,1] / fin[:,2])

#Discard 3rd column
fin = fin[:,0:2]

# Output

#with smoothing window 10
fin_w10 = np.copy(fin)
fin_w10[:,1] = uniform_filter1d(fin_w10[:,1], size=10)

fin_w10_x4 = np.copy(fin)
fin_w10_x4[:,1] = fin_w10_x4[:,1]*4
fin_w10_x4[:,1] = uniform_filter1d(fin_w10_x4[:,1], size=10)

#Save as .wig
np.savetxt("fin.wig", fin, fmt='%f', delimiter=' ', newline='\n', header=f'variableStep chrom={chrom} span=1', comments='')
np.savetxt("fin_w10.wig", fin_w10, fmt='%f', delimiter=' ', newline='\n', header=f'variableStep chrom={chrom} span=1', comments='')
np.savetxt("fin_w10_x4.wig", fin_w10_x4, fmt='%f', delimiter=' ', newline='\n', header=f'variableStep chrom={chrom} span=1', comments='')


