import pygame, math, random, time
from resources.config import *
from resources.robotService import getRawPos
# from resources.triggers import callTrigger
from resources.triggersDummy import callTrigger

def switchY(Y):
    w, h = pygame.display.get_surface().get_size()
    return h - Y
    # return Y

def getCenter():
    w, h = pygame.display.get_surface().get_size()
    return (w/2, h/2)

def scaleCoOrds(pos):
    (x,y) = pos
    x = (int(round(float(x) * 1000)) * 2) + CENTER
    y = (int(round(float(y) * 1000)) * 2) + CENTER
    # print(x,y)
    return (x,switchY(y))
    # return (x,y)
def createLog(log_filename, trigger, now, current):
    logPos = getPos()
    logVel = getVel()
    logStr = str(trigger) + ' ' + str(float(logPos[0])) + ' ' + str(float(logPos[1])) + ' ' + str(float(logVel[0])) + ' ' + str(float(logVel[1])) + ' ' + str(now) + ' ' + str(current) + '\n'
    writeLogs(log_filename, logStr)
    
def writeLogs(filename, strWrite):
    # strWrite = ''
    # for val in valArray:
    #     strWrite += str(val) + '\t'

    # strWrite += '\n'

    log_file = open(filename, 'a')
    log_file.write(strWrite)
    log_file.close()
    # path = logpath + str(filename)


def getPos():
    # pos = pygame.mouse.get_pos()
    # get robot position and velocity in fol format
    # output = x y vx vy (space seperated)
    
    output = str(getRawPos())
    output = output.strip()
    outArr = output.split()
    pos = (float(outArr[0]), float(outArr[1]))
    return scaleCoOrds(pos)
    
    # return (pos)

def getVel():
    output = ''
    output = str(getRawPos())
    output = output.strip()
    outArr = output.split()
    # print(outArr)
    return (float(outArr[2]), float(outArr[3]))


def draw_C1(screen):
    pygame.draw.circle(screen, BLACK, C1_POS, C1_RADIUS, C1_THICKNESS)

def draw_C2(screen):
    pygame.draw.circle(screen, BLACK, C1_POS, C2_RADIUS, C1_THICKNESS)

def draw_cross(screen, pos):
    crossImg = pygame.image.load('resources/images/cross.png')
    crossImg = pygame.transform.scale(crossImg, CROSS_SCALE)
    (x, y) = pos
    new_pos = [x - 8, switchY(y + (SCALE_UNIT / 2) - 6)]
    screen.blit(crossImg, new_pos)

def draw_arrow(screen, direction, pos, angle = None, back = False):
    # scale(Surface, (width, height), DestSurface = None) -> Surface
    (x, y) = pos
    if direction is 'up':
        crossImg = pygame.image.load('resources/images/arrow_up.png')
        crossImg = pygame.transform.scale(crossImg, VERTICAL_ARROW_SCALE)
        new_pos = [x - (ARROW_SCALE_UNIT_SMALL / 2) + 6, y - (ARROW_SCALE_UNIT_BIG / 2) ]
    elif direction is 'left':
        crossImg = pygame.image.load('resources/images/arrow_left.png')
        crossImg = pygame.transform.scale(crossImg, HORIZONTAL_ARROW_SCALE)
        new_pos = [x - (ARROW_SCALE_UNIT_BIG / 2) + 6, y - (ARROW_SCALE_UNIT_SMALL / 2) ]
    elif direction is 'right':
        crossImg = pygame.image.load('resources/images/arrow_right.png')
        crossImg = pygame.transform.scale(crossImg, HORIZONTAL_ARROW_SCALE)
        new_pos = [x - (ARROW_SCALE_UNIT_BIG / 2) + 6, y - (ARROW_SCALE_UNIT_SMALL / 2) ]
    # elif direction is 'down':
    else:
        crossImg = pygame.image.load('resources/images/arrow_down.png')
        crossImg = pygame.transform.scale(crossImg, VERTICAL_ARROW_SCALE)
        new_pos = [x - (ARROW_SCALE_UNIT_SMALL / 2) + 6, y - (ARROW_SCALE_UNIT_BIG / 2) ]
    if back:
        # crossImg = pygame.image.load('resources/images/arrow_up.png')
        # crossImg = pygame.transform.scale(crossImg, UP_ARROW_SCALE)
        crossImg = pygame.transform.rotate(crossImg, angle * -1)
    screen.blit(crossImg, new_pos)
'''
Returns true if moving, false otherwise
'''
def check_movement():
    vel = getVel()
    # vel = [0, 0]
    
    if abs(vel[0]) > THRESHOLD_VELOCITY or abs(vel[1]) > THRESHOLD_VELOCITY:
        # print(vel)
        # print(abs(vel[0]), abs(vel[1]))
        return True
    else:
        return False
'''
get the third point to calculate the angle to rotate the arrow by
'''
def third_point(direction, pos):
    (x, y) = pos
    if direction is 'up':
        y += 30
    elif direction is 'left':
        x -= 30
    elif direction is 'right':
        x += 30
    else:
        y -= 30

    return (x, y)


def get_angle(p1, p2, p3):
    print(p1, p2, p3)
    angle = (math.atan2(p3[1] - p1[1], p3[0] - p1[0]) - math.atan2(p2[1] - p1[1], p2[0] - p1[0]))
    return angle*180/math.pi

def get_game_direction(val):
    if val is 1:
        return 'up'
    elif val is 2:
        return 'right'
    elif val is 3:
        return 'down'
    else:
        return 'left'        

def get_distance(p1, p2):
    return math.hypot(p2[0] - p1[0], p2[1] - p1[1])

def check_in_center(pos):
    if get_distance(pos, getCenter()) < C2_RADIUS:
        return True
    else:
        return False

def outside_mid_circle(pos):
    if get_distance(pos, getCenter()) > CMID_RADIUS:
        return True
    else:
        return False

def get_trigger_direction(direction, in_out):
    trigger = 0
    if in_out == 'in':
        if direction == 'up':
            trigger = 14
        elif direction == 'right':
            trigger = 12
        elif direction == 'down':
            trigger = 10
        else:
            trigger = 1
    else:
        if direction == 'up':
            trigger = 15
        elif direction == 'right':
            trigger = 13
        elif direction == 'down':
            trigger = 11
        else:
            trigger = 9

    return trigger

def fire_trigger(trigger_old, trigger):
    if trigger_old == trigger:
        pass
    else:
        callTrigger(str(trigger))
        trigger_old = trigger
    return trigger_old