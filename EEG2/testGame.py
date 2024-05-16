import pygame
from pygame.locals import *
import math
import random
from testConfig import *
import time
#import numpy

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
'''
def calculate_normal(incomingVector, normal, point, initlen):    
    scale = (2*numpy.dot(incomingVector, normal))
    # print(f'scale: {scale}')
    outVector = [incomingVector[0] - scale*normal[0], incomingVector[1] - scale*normal[1]]
    outPoint = [outVector[0] + point[0], outVector[1] + point[1]]
    finalLen = math.hypot(outPoint[0] - point[0], outPoint[1] - point[1])
    # print(f'initlen: {initlen} finalLen: {finalLen}')
    t = initlen / finalLen
    newCoords = [((1 - t)*point[0] + t*outPoint[0]), ((1 - t)*point[1] + t*outPoint[1])]
    # print(f'new coords: {((1 - t)*point[0] + t*outPoint[0]), ((1 - t)*point[1] + t*outPoint[1])}')
    return [newCoords[0]-point[0], newCoords[1]-point[1]]

'''
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
            # print(f'circleBall.change_x: {circleBall.change_x} circleBall.change_y: {circleBall.change_y}')
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

            # print(f'circleBall.change_x: {circleBall.change_x} circleBall.change_y: {circleBall.change_y}\n')
        
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
        # print(game_counter)
        if index == GREEN_CIRCLE[game_counter - 1]:
            pygame.draw.circle(screen, GREEN, [circle.x, circle.y], CIRCLE_RADIUS)
        else:
            pygame.draw.circle(screen, BLACK, [circle.x, circle.y], CIRCLE_RADIUS)
        index += 1

# game iter is the iteration of the game, which trial it is on
def checkPos(circle_list, game_counter):
    checked = False
    pos = getPos()
    # print(GAME_ITER)
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
        # print(f'{circle1.x} 500, {circle1.y} 500')
        old_coordinates.append(circle1.x)
        old_coordinates.append(circle1.y)
        distance = math.hypot(circle1.x - 500, switchY(circle1.y) - 500)
    else:
        # circle2 = circle_list[GREEN_CIRCLE[game_counter - 1]]
        # print(f'{circle1.x} {old_coordinates[0]}, {circle1.y} {old_coordinates[1]}')
        distance = math.hypot(circle1.x - old_coordinates[0], switchY(circle1.y) - old_coordinates[1])
        old_coordinates = []
        old_coordinates.append(circle1.x)
        old_coordinates.append(circle1.y)
    return distance, old_coordinates

def switchY(Y):
    w, h = pygame.display.get_surface().get_size()
    return h - Y
    # return Y

# running = True
def main():
    global running, screen

    pygame.init()

    # set the game in Full Screen
    screen = pygame.display.set_mode(SIZE, FULLSCREEN)
    pygame.display.set_caption(CAPTION)

    pointerImg = pygame.image.load('resources/images/reddot.png')
    pointerImg_rect = pointerImg.get_rect()
    cursor_picture = pygame.image.load('resources/images/reddot.png').convert_alpha()

    fps = pygame.time.Clock()

    circle_list = make_circle()

    game_counter = 0

    old_coordinates = []

    pygame.mouse.set_cursor((8,8),(0,0),(0,0,0,0,0,0,0,0),(0,0,0,0,0,0,0,0))

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

            pointerImg_rect.center = pygame.mouse.get_pos()

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

            drawCircleInitial(circle_list)
            move_circle(circle_list)
            # drawCircle(circle_list)
            # lapsed = now - last

            # if lapsed < 1000:
            #     drawCircleInitial(circle_list)
            # elif lapsed >= 1000 and lapsed < 3000:
            #     drawCircle(circle_list)
            # elif lapsed >= 3000 and lapsed < 8000:
            #     drawCircleInitial(circle_list)
            #     move_circle(circle_list)
            # elif lapsed >= 8000 and lapsed < 9000:
            #     drawCircleInitial(circle_list)
            # elif lapsed >= 9000 and lapsed < 14000:
            #     drawCircleGreen(circle_list, game_counter)
            #     if checkPos(circle_list, game_counter):
            #         if IS_TARGET[GREEN_CIRCLE[game_counter - 1]]:
            #             success = 1
            #         else:
            #             success = 0
            #         distance, old_coordinates = getDistanceMoved(game_counter - 1, circle_list, old_coordinates)

            #         timeArr.append(time.time())
            #         timeArr.append(success)
            #         timeArr.append(round(distance, 2))

            #         running = False
            # else:
            #     timeArr.append(time.time())
            #     running = False

            screen.blit(pointerImg_rect, pygame.mouse.get_pos())
            # screen.blit(cursor_picture, pygame.mouse.get_pos())

            fps.tick(60)

            pygame.display.flip()

        # writeLogs(filename, timeArr)




if __name__ == '__main__':
    main()
