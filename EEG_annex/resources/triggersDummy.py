import sys

def fireTrigger(trigger):

    if trigger == "0":
        send = 0b00000000
    elif trigger =="1":
        send = 0b00000001
    elif trigger =="2":
        send = 0b00000010
    elif trigger =="3":
        send = 0b00000011
    elif trigger =="4":
        send = 0b00000100
    elif trigger =="5":
        send = 0b00000101
    elif trigger =="6":
        send = 0b00000110
    elif trigger =="7":
        send = 0b00000111
    elif trigger =="8":
        send = 0b00001000
    elif trigger =="9":
        send = 0b00001001
    elif trigger =="10":
        send = 0b00001010
    elif trigger =="11":
        send = 0b00001011
    elif trigger =="12":
        send = 0b00001100
    elif trigger =="13":
        send = 0b00001101
    elif trigger =="14":
        send = 0b00001110
    elif trigger =="15":
        send = 0b00001111
    elif trigger =="16":
        send = 0b00010000
    elif trigger =="17":
        send = 0b00010001
    elif trigger == "18":
        send = 0b00010010
    
    print(send)
    # uncomment below when firing trigger. Otherwise print to view output
    #dev.write_port(0, send)

def callTrigger(trigger):
    fireTrigger(trigger)
    fireTrigger('0')
