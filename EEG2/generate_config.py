import random
from config import *

x_arr = []
y_arr = []
change_x_arr = []
change_y_arr = []
green_circle = []
is_target = [False] * NO_OF_CIRCLES

for i in range(NO_OF_CIRCLES):
    # x_arr.append(random.randrange(CIRCLE_RADIUS, 707 - CIRCLE_RADIUS))
    # y_arr.append(random.randrange(CIRCLE_RADIUS, 707 - CIRCLE_RADIUS))
    x_arr.append(random.randrange(BOUNDARY_CIRCLE_CENTER - 353 + CIRCLE_RADIUS, BOUNDARY_CIRCLE_CENTER + 353 - CIRCLE_RADIUS))
    y_arr.append(random.randrange(BOUNDARY_CIRCLE_CENTER - 353 + CIRCLE_RADIUS, BOUNDARY_CIRCLE_CENTER + 353 - CIRCLE_RADIUS))
    change_x_arr.append(random.randrange(-2, 3))
    change_y_arr.append(random.randrange(-2, 3))

for i in random.sample(range(NO_OF_CIRCLES), NO_OF_CIRCLES_GREEN):
	is_target[i] = True

for i in random.sample(range(NO_OF_CIRCLES), GAME_ITER):
	green_circle.append(i)

print('NUMBER_OF_CIRCLES = {}'.format(NO_OF_CIRCLES))
print('X_ARR = {}'.format(x_arr))
print('Y_ARR = {}'.format(y_arr))
print('CHANGE_X_ARR = {}'.format(change_x_arr))
print('CHANGE_Y_ARR = {}'.format(change_y_arr))
print('IS_TARGET = {}'.format(is_target))
print('GREEN_CIRCLE = {}'.format(green_circle))