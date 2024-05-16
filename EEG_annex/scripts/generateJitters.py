import random

random.seed(3)
x = range(402)
y = [int(random.uniform(800,1200)) for i in x]

# print(y)

jitters = " ".join(str(i) for i in y)

print(jitters)
