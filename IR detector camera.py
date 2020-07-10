import gpiozero
from picamera import PiCamera, Color
from time import sleep
from datetime import datetime
import os

irSensor = gpiozero.Button(14, pull_up=False)
relay = gpiozero.DigitalOutputDevice(4, active_high=False)
offbutton = gpiozero.Button(26)

camera = PiCamera()
camera.rotation = 180
#camera.framerate = 15
#camera.resolution = (3280,2464)
camera.framerate = 30
camera.resolution = (1640,1232)
camera.annotate_background = Color('black')

#base_directory = '/media/pi/CCCOMA_X64FRE_EN-US_DV9/photos/'
base_directory = '/home/pi/'

recording = -1

def start_recording():
    relay.on()
    print('IR LED ON - recording')
    global recording
    recording = 15
    date = datetime.now().strftime("%Y/%m/%d/")
    filename = datetime.now().strftime("%H%M%S")
    os.makedirs(base_directory+date, exist_ok=True)
    try:
        camera.start_recording(base_directory+date+filename+'.h264')
    except:
        pass

def update_annotate():
    global recording
    print('Recording for', recording, 'more seconds')
    camera.annotate_text = datetime.now().strftime("%H:%M:%S %d/%m/%Y")
    recording -= 1
    sleep(1)
  
def stop_recording():
    global recording
    recording = -1
    print('IR LED OFF - stopped recording')
    try:
        camera.stop_recording()
    except:
        pass
    relay.off()

def shutdown():
    irSensor.close()
    relay.off()
    sleep(.25)
    relay.on()
    sleep(.25)
    relay.off()
    sleep(.25)
    try:
        stop_recording()
    finally:
        relay.close()
        print('Shutting down')
        os.system('shutdown now')

irSensor.when_released = start_recording
offbutton.when_released = shutdown

while True:
    if recording > 0:
      update_annotate()
    elif recording == 0:
      stop_recording()
