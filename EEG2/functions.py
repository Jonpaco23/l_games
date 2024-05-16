import math

P1 = [0,0]
P3 = [90,0]
P2 = [0,90]

theta = math.atan2(P2[1] - P1[1], P2[0] - P1[0]) - math.atan2(P3[1] - P1[1], P3[0] - P1[0])
print(theta*2)
# print(round(math.cos(theta), 2))
# print(math.sin(theta))
print(math.degrees(theta))
print(math.radians(2*math.degrees(theta)))