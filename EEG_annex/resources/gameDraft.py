import pygame
from pygame.locals import *
from resources.config import *
# from resources.circle import Circle
from resources.functions import *
# from resources.triggers import callTrigger
# from resources.triggersDummy import callTrigger

class Game:
    def __init__(self, display, player_name):
        self.display = display
        self.player_name = player_name
        self.score = 0
        self.rounds = 0
        self.triggerFlag = []
        self.log_filename = LOG_PATH + player_name + '_' + str(int(time.time())) + str('.log')
        self.pos = [500, 500]
        pygame.init()

    def loop(self):
        fps = pygame.time.Clock()
        # circle_list = make_circle()
        old_coordinates = []
        # pygame.time.wait(5000)
        pygame.mouse.set_visible(False)

        # testcode
        pointerImg = pygame.image.load('resources/images/new_dot.png')
        pointerImg_rect = pointerImg.get_rect()

        # self.display.fill(WHITE)

        while GAME_ITER > self.rounds:
            # counter to keep track of number of rounds taking place
            self.rounds += 1

            #timekeeping
            last = pygame.time.get_ticks()

            running = True

            self.triggerFlag = [True for i in range(9)]

            # timeArr used to keep track of events happening
            timeArr = []
            # insert start time
            timeArr.append(time.time())
            # if self.triggerFlag[0]:
            #     callTrigger('1')
            #     self.triggerFlag[0] = False

            # flags
            game_start = False
            back_arrow_display = False

            # get game direction
            game_direction = get_game_direction(DIRECTION_ARRAY[self.rounds - 1])
            print('Starting game in ' + game_direction + ' direction')

            # start main game loop
            while running:
                # pointerImg_rect.center = pygame.mouse.get_pos()
                # self.display.blit(pointerImg, pygame.mouse.get_pos())
                now = pygame.time.get_ticks()
                elapsed = last - now

                self.display.fill(WHITE)

                # CONTROL BLOCK
                # block to control key press events
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
                            self.display.fill(white)
                            if self.display.get_flags() & FULLSCREEN:
                                pygame.display.set_mode(SIZE)
                            else:
                                pygame.display.set_mode(SIZE, FULLSCREEN)
                # CONTROL BLOCK ENDS


                draw_C1(self.display)

                
                # draw_arrow(self.display, 'up', [500, 500])
                # print(getVel())
                # print(getCenter())
                # angle = get_angle(third_point('up', getPos()), getPos(), getCenter())
                # if int(angle) > 0:
                #     draw_arrow(self.display, 'back', getPos(), angle)
                # else:
                #     draw_arrow(self.display, 'up', [500, 500])
                # print(angle)
                flag = check_movement()
                if flag:
                    game_start = True

                # if round has started and player has stopped moving
                if game_start:
                    if flag:
                        if back_arrow_display:
                            draw_arrow(self.display, game_direction, back_pos, angle, True)
                        else:
                            draw_arrow(self.display, game_direction, [500, 500])
                        # draw_arrow(self.display, game_direction, back_pos, angle, True)
                    else:
                        if back_arrow_display:
                            draw_arrow(self.display, game_direction, back_pos, angle, True)
                            # if cursor back to center
                            if check_in_center(getPos()):
                                running = False
                        else:
                            # rotate the arrow to point back to center
                            print('Returning back to the center')
                            if game_direction in ['up', 'down']:
                                angle = get_angle(third_point(game_direction, getPos()), getPos(), getCenter())
                            else:
                                angle = get_angle(getPos(), third_point(game_direction, getPos()), getCenter())
                            print(angle)
                            if int(abs(angle)) > 0:
                                back_pos = getPos()
                                draw_arrow(self.display, game_direction, back_pos, angle, True)
                                back_arrow_display = True
                            # round should end when user reaches back to center
                            # if user doesn't reach center soon enough, cross should appear to direct him towards it
                else:
                    draw_arrow(self.display, game_direction, [500, 500])


                '''
                # draw background circle
                # TODO: Move this outside game loop
                pygame.draw.circle(self.display, 
                    WHITE, 
                    [BOUNDARY_CIRCLE_CENTER, BOUNDARY_CIRCLE_CENTER], 
                    BOUNDARY_CIRCLE_RADIUS)

                # Keeping track of time, reset after each iteration
                lapsed = now - last

                # self.display.blit(pointerImg, getPos())

                # Control block for the 1st second
                if lapsed < (1*1000):
                    drawCircleInitial(circle_list, self.display)
                # Control block from 1 to 3 seconds
                elif lapsed >= (1*1000) and lapsed < (3*1000):
                    if self.triggerFlag[1]:
                        callTrigger('2')
                        self.triggerFlag[1] = False
                    drawCircle(circle_list, self.display)
                # Control block from 3 to 8 seconds
                elif lapsed >= (3*1000) and lapsed < (8*1000):
                    if self.triggerFlag[2]:
                        callTrigger('3')
                        self.triggerFlag[2] = False
                    if self.triggerFlag[3]:
                        callTrigger('4')
                        self.triggerFlag[3] = False
                    drawCircleInitial(circle_list, self.display)
                    move_circle(circle_list)
                # Control block from 8 to 9 seconds
                elif lapsed >= (8*1000) and lapsed < (9*1000):
                    if self.triggerFlag[4]:
                        callTrigger('5')
                        self.triggerFlag[4] = False
                    drawCircleInitial(circle_list, self.display)
                # Control block from 9 to 14 seconds
                elif lapsed >= (9*1000) and lapsed < (14*1000):
                    if self.triggerFlag[5]:
                        callTrigger('6')
                        self.triggerFlag[5] = False
                        old_pos = getPos()
                    drawCircleGreen(circle_list, self.rounds, self.display)
                    new_pos = getPos()
                    if deltaMove(old_pos, new_pos):
                        if self.triggerFlag[6]:
                            callTrigger('7')
                            self.triggerFlag[6] = False
                    # if deltaVel(getVel()):
                    #     callTrigger('7')
                    
                    if checkPos(circle_list, self.rounds):
                        if IS_TARGET[GREEN_CIRCLE[self.rounds - 1]]:
                            success = 1
                            if self.triggerFlag[7]:
                                callTrigger('8')
                                self.triggerFlag[7] = False
                        else:
                            success = 0
                        distance, old_coordinates = getDistanceMoved(self.rounds - 1, circle_list, old_coordinates)

                        timeArr.append(time.time())
                        timeArr.append(success)
                        timeArr.append(round(distance, 2))

                        running = False
                        if self.triggerFlag[8]:
                            callTrigger('9')
                            self.triggerFlag[8] = False
                        circle_list = reload_targets(circle_list)
                # Control block post 14 seconds
                else:
                    timeArr.append(time.time())
                    running = False
                    if self.triggerFlag[8]:
                        callTrigger('9')
                        self.triggerFlag[8] = False
                    circle_list = reload_targets(circle_list)
                '''
                self.display.blit(pointerImg, getPos())
                
                fps.tick(60)

                pygame.display.flip()

            writeLogs(self.log_filename, timeArr)