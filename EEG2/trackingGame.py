import pygame
from pygame.locals import *
import math
import random
from config import *
import time

# old_coordinates = []

# class to keep track of each circle created
class Circle:
    def __init__(self):
        self.x = 0
        self.y = 0
        self.change_x = 0
        self.change_y = 0
        self.is_target = False

def make_circle():
    circle_list = []
    for i in range(NUMBER_OF_CIRCLES):
        circleBall = Circle()

        circleBall.x = X_ARR[i]
        circleBall.y = Y_ARR[i]
 
        circleBall.change_x = CHANGE_X_ARR[i]
        circleBall.change_y = CHANGE_Y_ARR[i]

        circleBall.is_target = IS_TARGET[i]

        circle_list.append(circleBall)
 
    return circle_list

# returns true if x,y is outside the circle
def checkOutsideCircle(posX, posY):
    # d is distance of the point from the cetner
    d = math.hypot(posX - BOUNDARY_CIRCLE_RADIUS, switchY(posY) - switchY(BOUNDARY_CIRCLE_RADIUS))
    if d > BOUNDARY_CIRCLE_RADIUS - CIRCLE_RADIUS:
        return True
    else:
        return False

def move_circle(circle_list):
    for circleBall in circle_list:
        circleBall.x += circleBall.change_x
        circleBall.y += circleBall.change_y

        if checkOutsideCircle(circleBall.x, circleBall.y):
            # since the point is outside, we first move back one frame
            circleBall.x -= circleBall.change_x
            circleBall.y -= circleBall.change_y

            # we now switch dx and dy since we're taking the normal
            temp_dx = circleBall.change_y
            temp_dy = circleBall.change_x
            temp_x = circleBall.x + temp_dx
            temp_y = circleBall.y + temp_dy

            # now we check which of x,y should be negative to give us the right direction
            temp_dx *= -1
            temp_x = circleBall.x + temp_dx
            
            # we check if normal point is outside circle
            if checkOutsideCircle(temp_x, temp_y):
                # since it isn't we switch
                temp_x = circleBall.x - temp_dx
                temp_dx *= -1
                temp_dy *= -1
                temp_y = circleBall.y + temp_dy

                if checkOutsideCircle(temp_x, temp_y):
                    # since this wasn't right either, we fall back to older option of simply reversing both dx and dy
                    circleBall.change_x *= -1
                    circleBall.change_y *= -1
                else:
                    circleBall.change_x = temp_dx
                    circleBall.change_y = temp_dy
            else:
                circleBall.change_x = temp_dx
                circleBall.change_y = temp_dy

            circleBall.x += circleBall.change_x
            circleBall.y += circleBall.change_y 
# def move_circle(circle_list):
#     for circleBall in circle_list:
#         circleBall.x += circleBall.change_x
#         circleBall.y += circleBall.change_y

#         # d is distance of the point from the cetner
#         d = math.hypot(circleBall.x - BOUNDARY_CIRCLE_RADIUS, switchY(circleBall.y) - switchY(BOUNDARY_CIRCLE_RADIUS))
        
#         if d > BOUNDARY_CIRCLE_RADIUS - CIRCLE_RADIUS:
#             circleBall.change_y *= -1
#             circleBall.change_x *= -1
 
        
def getPos():
    pos = pygame.mouse.get_pos()
    return (pos)

def drawCircleInitial(circle_list):
    for circle in circle_list:
        pygame.draw.circle(screen, BLACK, [circle.x, circle.y], CIRCLE_RADIUS)

def drawCircle(circle_list):
    for circle in circle_list:
        if circle.is_target:
            pygame.draw.circle(screen, BLUE, [circle.x, circle.y], CIRCLE_RADIUS)
        else:
            pygame.draw.circle(screen, BLACK, [circle.x, circle.y], CIRCLE_RADIUS)

def drawCircleGreen(circle_list, game_counter):
    index = 0
    for circle in circle_list:
        if index == GREEN_CIRCLE[game_counter - 1]:
            pygame.draw.circle(screen, GREEN, [circle.x, circle.y], CIRCLE_RADIUS)
        else:
            pygame.draw.circle(screen, BLACK, [circle.x, circle.y], CIRCLE_RADIUS)
        index += 1

# game iter is the iteration of the game, which trial it is on
def checkPos(circle_list, game_counter):
    checked = False
    pos = getPos()
    circle = circle_list[GREEN_CIRCLE[game_counter - 1]]
    if (circle.x - CIRCLE_RADIUS <= pos[0] <= circle.x + CIRCLE_RADIUS) and (circle.y - CIRCLE_RADIUS <= pos[1] <= circle.y + CIRCLE_RADIUS):
        checked = True

    return checked

def writeLogs(filename, valArray):
    strWrite = ''
    for val in valArray:
        strWrite += str(val) + '\t'

    strWrite += '\n'

    log_file = open(filename, 'a')
    log_file.write(strWrite)
    log_file.close()
    # path = logpath + str(filename)

def getDistanceMoved(game_counter, circle_list, old_coordinates):
    circle1 = circle_list[GREEN_CIRCLE[game_counter]]
    if game_counter == 0:
        # distance from center
        old_coordinates.append(circle1.x)
        old_coordinates.append(circle1.y)
        distance = math.hypot(circle1.x - 500, switchY(circle1.y) - 500)
    else:
        # circle2 = circle_list[GREEN_CIRCLE[game_counter - 1]]
        distance = math.hypot(circle1.x - old_coordinates[0], switchY(circle1.y) - old_coordinates[1])
        old_coordinates = []
        old_coordinates.append(circle1.x)
        old_coordinates.append(circle1.y)
    return distance, old_coordinates

def switchY(Y):
    w, h = pygame.display.get_surface().get_size()
    return h - Y
    # return Y

# change targets so that the same targets don't appear again
def reload_targets(circle_list):
    temp = IS_TARGET[0]
    for index in range(len(IS_TARGET) - 1):
        IS_TARGET[index] = IS_TARGET[index + 1]
    IS_TARGET[-1] = temp

    i = 0
    for circleBall in circle_list:
        circleBall.is_target = IS_TARGET[i]
        i += 1

    return circle_list

def main():
    global running, screen

    pygame.init()

    # set the game in Full Screen
    screen = pygame.display.set_mode(SIZE, FULLSCREEN)
    pygame.display.set_caption(CAPTION)

    fps = pygame.time.Clock()

    circle_list = make_circle()

    game_counter = 0

    old_coordinates = []

    # build log name
    filename = logpath + str(int(time.time())) + str('.log')

    while GAME_ITER > game_counter:
        game_counter += 1

        last = pygame.time.get_ticks()

        running = True

        timeArr = []
        timeArr.append(time.time())

        # Main Program Loop
        while running:
            now = pygame.time.get_ticks()

            # timeArr.append(time.time())

            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                    pygame.quit()
                # All key press events should be added here
                elif event.type == KEYDOWN:
                    # escape to quit
                    if event.key == K_ESCAPE:
                        running = False
                        pygame.quit()
                    # Start game with s
                    elif event.key == K_SPACE:
                        # drawCircle(circle_list)
                        pygame.display.update()
                    # Full Screen for 'f' key
                    elif event.key == K_f:
                        screen.fill(white)
                        if screen.get_flags() & FULLSCREEN:
                            pygame.display.set_mode(SIZE)
                        else:
                            pygame.display.set_mode(SIZE, FULLSCREEN)

            # screen.fill(WHITE)
            pygame.draw.circle(screen, 
                WHITE, 
                [BOUNDARY_CIRCLE_CENTER, BOUNDARY_CIRCLE_CENTER], 
                BOUNDARY_CIRCLE_RADIUS)

            # iteration starts here
            lapsed = now - last

            if lapsed < 1000:
                drawCircleInitial(circle_list)
            elif lapsed >= 1000 and lapsed < 3000:
                drawCircle(circle_list)
            elif lapsed >= 3000 and lapsed < 8000:
                drawCircleInitial(circle_list)
                move_circle(circle_list)
            elif lapsed >= 8000 and lapsed < 9000:
                drawCircleInitial(circle_list)
            elif lapsed >= 9000 and lapsed < 14000:
                drawCircleGreen(circle_list, game_counter)
                if checkPos(circle_list, game_counter):
                    if IS_TARGET[GREEN_CIRCLE[game_counter - 1]]:
                        success = 1
                    else:
                        success = 0
                    distance, old_coordinates = getDistanceMoved(game_counter - 1, circle_list, old_coordinates)

                    timeArr.append(time.time())
                    timeArr.append(success)
                    timeArr.append(round(distance, 2))

                    running = False
                    circle_list = reload_targets(circle_list)
            else:
                timeArr.append(time.time())
                running = False
                circle_list = reload_targets(circle_list)

            fps.tick(60)

            pygame.display.flip()

        writeLogs(filename, timeArr)




if __name__ == '__main__':
    main()