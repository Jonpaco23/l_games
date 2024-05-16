# from ctypes import cdll
from subprocess import check_output

def getRawPos():
    # sh_obj = cdll.LoadLibrary('/home/testac/crob/examples/getposvel.so')
    val = check_output('/home/testac/crob/examples/getposvel.o', shell=True)
    return val
