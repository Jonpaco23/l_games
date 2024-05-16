import pygame
from pygame.locals import *
from resources.config import *
from resources.functions import *
# from resources.triggers import callTrigger
from resources.triggersDummy import callTrigger

class Game:
    def __init__(self, display, player_name):
        self.display = display
        self.player_name = player_name
        self.score = 0
        self.rounds = 0
        self.last_fired_trigger = 0
        self.log_filename = LOG_PATH + player_name + '_' + str(int(time.time())) + str('.log')
        self.pos = [500, 500]
        pygame.init()
        pygame.font.init()

    def loop(self):
        myfont = pygame.font.SysFont('Comic Sans MS', 30)
        fps = pygame.time.Clock()
        # circle_list = make_circle()
        old_coordinates = []
        # pygame.time.wait(5000)
        pygame.mouse.set_visible(False)

        # testcode
        pointerImg = pygame.image.load('resources/images/new_dot.png')
        pointerImg_rect = pointerImg.get_rect()

        self.last_fired_trigger = fire_trigger(self.last_fired_trigger, 18)
        # self.display.fill(WHITE)

        break_var = False
        start_splash = False

        while GAME_ITER > self.rounds:
            # if self.rounds == BREAK_ROUND:

            #     textsurface = myfont.render('BREAK!!!', False, (0, 0, 0))
            #     self.display.fill(WHITE)
            #     if not break_var:
            #         break_time = pygame.time.get_ticks()
            #         break_var = True
            #         print('Starting Break!')
            #     if pygame.time.get_ticks() - break_time > BREAK_DURATION:
            #         self.rounds += 1
            #     else:
            #         self.display.blit(textsurface,(0,0))

            # else:
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
            
            # flags
            game_start = False
            going_back = False
            jitter_end = False
            jitter_mid = False

            # get game direction
            game_direction = get_game_direction(DIRECTION_ARRAY[self.rounds - 1])
            print('Starting game in ' + game_direction + ' direction')

            # start main game loop
            while running:
                # pointerImg_rect.center = pygame.mouse.get_pos()
                # self.display.blit(pointerImg, pygame.mouse.get_pos())
                now = pygame.time.get_ticks()
                elapsed = last - now
                logStr = ''

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

                if self.rounds == 1:
                    self.display.fill(WHITE)
                    if not start_splash:
                        start_time = pygame.time.get_ticks()
                        start_splash = True
                    if now - start_time > MESSAGE_DISPLAY_DURATION:
                        self.rounds += 1
                    else:
                        textsurface = myfont.render(START_MSG, False, (0, 0, 0))
                        self.display.blit(textsurface,(400,500))

                elif self.rounds == BREAK_ROUND:
                    self.display.fill(WHITE)
                    if not break_var:
                        self.last_fired_trigger = fire_trigger(self.last_fired_trigger, 16)
                        break_time = pygame.time.get_ticks()
                        break_var = True
                        print('Starting Break!')
                    if now - break_time > (BREAK_DURATION - MESSAGE_DISPLAY_DURATION):
                        textsurface = myfont.render(RESUME_MSG, False, (0, 0, 0))
                        self.display.blit(textsurface,(400,500))
                        if now - break_time > BREAK_DURATION:
                            self.last_fired_trigger = fire_trigger(self.last_fired_trigger, 17)
                            self.rounds += 1
                            print('Break Over!')
                    else:
                        textsurface = myfont.render(BREAK_MSG, False, (0, 0, 0))
                        self.display.blit(textsurface,(300,500))
                else:        
                    draw_C1(self.display)

                    if jitter_end:
                        if now - jitter_end_time > JITTER_END_ARRAY[self.rounds - 1]:
                            # self.last_fired_trigger = fire_trigger(self.last_fired_trigger, 6)
                            running = False
                            jitter_end = False

                    elif jitter_mid:
                        if now - jitter_mid_time > JITTER_MID_ARRAY[self.rounds - 1]:
                            self.last_fired_trigger = fire_trigger(self.last_fired_trigger, 7)
                            draw_C2(self.display)
                            going_back = True
                            jitter_mid = False

                    else:
                        # condition before the user has started moving
                        if not game_start:
                            self.last_fired_trigger = fire_trigger(self.last_fired_trigger, 7)
                            draw_arrow(self.display, game_direction, [500, 500])

                        moving_flag = check_movement()

                        if moving_flag:
                            game_start = True

                        if game_start: # user has started moving 
                            if going_back:
                                if moving_flag:
                                    self.last_fired_trigger = fire_trigger(self.last_fired_trigger, get_trigger_direction(game_direction, 'in'))
                                draw_C2(self.display)
                                if check_in_center(getPos()):
                                    self.last_fired_trigger = fire_trigger(self.last_fired_trigger, 2)
                                    # self.last_fired_trigger = fire_trigger(self.last_fired_trigger, 6)
                                    jitter_end = True
                                    jitter_end_time = pygame.time.get_ticks()
                            else:
                                # draw_arrow(self.display, game_direction, [500, 500])
                                self.last_fired_trigger = fire_trigger(self.last_fired_trigger, get_trigger_direction(game_direction, 'out'))
                                if not moving_flag: # user has stopped moving
                                    if outside_mid_circle(getPos()):
                                        self.last_fired_trigger = fire_trigger(self.last_fired_trigger, 2)
                                        jitter_mid = True
                                        jitter_mid_time = pygame.time.get_ticks()       
                                        # draw_C2(self.display)
                                        # going_back = True
                                    else:
                                        draw_arrow(self.display, game_direction, [500, 500])    
                                else:
                                    draw_arrow(self.display, game_direction, [500, 500])
                createLog(self.log_filename, self.last_fired_trigger, now, pygame.time.get_ticks())
                
                self.display.blit(pointerImg, getPos())
                
                fps.tick(60)

                pygame.display.flip()

        self.last_fired_trigger = fire_trigger(self.last_fired_trigger, 8)

        textsurface = myfont.render(GAME_OVER_MSG, False, (0, 0, 0))
        self.display.blit(textsurface,(450,500))
        fps.tick(60)
        pygame.display.flip()