import pygame, sys
from pygame.locals import *

from resources.config import *
from resources.game import Game

def main(player_name = 'unamed'):
    # set the game in Full Screen
    screen = pygame.display.set_mode(SIZE, FULLSCREEN)
    # screen = pygame.display.set_mode(SIZE)
    pygame.display.set_caption(CAPTION)

    game = Game(screen, player_name)
    game.loop()
    print('Run Success')


if __name__ == '__main__':
    name = sys.argv[1]
    main(name)
