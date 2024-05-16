#!/usr/bin/python

#This was used to pregenerate the list of random target locations 
import numpy as np

y = np.random.randint(2, size=402)

print(y)

jitters = " ".join(str(i) for i in y)

print(jitters)