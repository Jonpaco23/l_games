'''
Log file to store variables
'''
# log path
LOG_PATH = 'logs/'

# Caption
CAPTION = 'Arm Bot EEG Game'

# Colors
WHITE = [255, 255, 255]
BLUE = [0, 0, 255]
BLACK = [0, 0, 0]
GREEN = [0, 255, 0]
RED = [255, 0, 0]

# Screen Size
SCREEN_WIDTH = 1000
SCREEN_HEIGHT = 1000
SIZE = [SCREEN_WIDTH, SCREEN_HEIGHT]

GAME_ITER = 122

# C1 Outer circle displayed dimensions
C1_POS = [500, 500]
C1_RADIUS = 275
C1_THICKNESS = 4

# C2 is the smaller inner cricle that appears when the cursor has to move back
C2_RADIUS = 20
# CMID radius is the same as C1_Radius which is the point at which the game checks if cursor is moving or not
CMID_RADIUS = 275

# cross scaling 
SCALE_UNIT = 30
CROSS_SCALE = [SCALE_UNIT, SCALE_UNIT]

# arrow scaling big and small for horizontal and vertical images
ARROW_SCALE_UNIT_BIG = 80
ARROW_SCALE_UNIT_SMALL = 40
VERTICAL_ARROW_SCALE = [ARROW_SCALE_UNIT_SMALL, ARROW_SCALE_UNIT_BIG]
HORIZONTAL_ARROW_SCALE = [ARROW_SCALE_UNIT_BIG, ARROW_SCALE_UNIT_SMALL]

# threshold velocity to check when cursor starts moving
THRESHOLD_VELOCITY = 0.02
CENTER = 500

# same number of values as GAME_ITER+
# DIRECTION_ARRAY = [4,4,4,4,4,4,4]
DIRECTION_ARRAY = [4, 1, 4, 1, 3, 1, 2, 1, 2, 2, 4, 4, 3, 2, 1, 1, 2, 2, 2, 4, 1, 4, 3, 3, 3, 3, 2, 4, 2, 1, 3, 1, 3, 4, 3, 1, 4, 1, 2, 4, 1, 2, 2, 3, 1, 3, 4, 1, 4, 3, 3, 1, 2, 2, 4, 1, 1, 3, 2, 2, 4, 2, 4, 3, 2, 2, 2, 4, 2, 1, 2, 4, 3, 3, 1, 3, 1, 4, 3, 2, 2, 2, 4, 1, 2, 2, 1, 3, 2, 3, 1, 4, 1, 4, 2, 1, 1, 4, 1, 4, 1, 1, 2, 2, 4, 4, 1, 2, 1, 3, 4, 3, 3, 1, 4, 4, 3, 3, 3, 1, 3, 3, 2, 4, 2, 3, 2, 3, 3, 2]
JITTER_END_ARRAY = [1187, 1057, 894, 821, 999, 991, 810, 902, 914, 1047, 1088, 909, 985, 927, 1148, 1027, 1075, 995, 1022, 941, 934, 1141, 1088, 899, 1038, 1015, 1037, 980, 1064, 896, 1087, 960, 1162, 1090, 1064, 805, 939, 942, 917, 814, 999, 871, 1050, 1004, 900, 1003, 1191, 1173, 1013, 1029, 1122, 907, 974, 952, 1103, 1200, 819, 943, 819, 904, 1113, 1036, 1193, 1060, 814, 918, 1173, 853, 934, 1199, 1179, 1199, 897, 1092, 891, 867, 974, 886, 851, 1137, 1184, 1078, 1163, 836, 841, 1192, 1150, 1133, 1069, 1140, 1131, 1104, 974, 1196, 1149, 1067, 1084, 1063, 1119, 906, 1143, 1041, 1192, 834, 870, 1033, 842, 928, 887, 1098, 1000, 963, 1196, 991, 986, 977, 1122, 849, 911, 1019, 972, 883, 826, 899, 1102, 1100, 1157, 899, 1072, 1069]
JITTER_MID_ARRAY = [1199, 907, 922, 905, 803, 914, 862, 1068, 1153, 916, 1177, 849, 925, 874, 824, 1155, 1174, 1006, 1111, 1106, 860, 893, 1049, 889, 1007, 1080, 941, 1187, 847, 941, 873, 1190, 1059, 1075, 1188, 1099, 907, 932, 1095, 1032, 1097, 980, 1044, 835, 884, 1004, 961, 1112, 1006, 1163, 846, 1055, 831, 1099, 1135, 1104, 1140, 1003, 839, 909, 839, 991, 985, 1031, 1052, 856, 933, 962, 870, 1010, 1116, 1062, 836, 1186, 1095, 891, 856, 951, 1058, 873, 1070, 973, 1122, 897, 1103, 807, 1068, 870, 1097, 899, 1034, 1015, 850, 1041, 1124, 852, 1018, 1130, 1128, 1171, 812, 1146, 843, 1173, 826, 925, 1163, 857, 1007, 957, 1040, 811, 995, 852, 1166, 1028, 985, 810, 946, 1021, 943, 1105, 941, 1148, 1043, 828, 1157, 928, 862, 1117]

# inner circle is the circle at the center that we check when returning to center
INNER_CIRCLE_RADIUS = 10

# Round when the break happens
BREAK_ROUND = 70
# Entire duration of the break
BREAK_DURATION = 90000

# time to display the message for (in miliseconds)
MESSAGE_DISPLAY_DURATION = 5000

# Messages to display during the game
BREAK_MSG = 'Starting the break now. Game will resume soon.'
RESUME_MSG = 'Game resuming in 5 seconds'
START_MSG = 'Game starting in 5 seconds'
GAME_OVER_MSG = 'Game Over'