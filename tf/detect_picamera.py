from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import argparse
import io
import re

from datetime import datetime #date and time
import os #usb drive file operations

import numpy as np
import picamera #camera

from PIL import Image
from tflite_runtime.interpreter import Interpreter #tensorflow

import shutil #usb drive usage

from gpiozero import CPUTemperature #cpu temperature

CAMERA_WIDTH = 3280
CAMERA_HEIGHT = 2464
storage_location = "/home/pi/Desktop/usb/"

import csv #logging
csvlog = csv.writer(open(storage_location+'log.csv', 'a', buffering=1, newline=''), strict=1)

def load_labels(path):
  """Loads the labels file. Supports files with or without index numbers."""
  with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()
    labels = {}
    for row_number, content in enumerate(lines):
      pair = re.split(r'[:\s]+', content.strip(), maxsplit=1)
      if len(pair) == 2 and pair[0].strip().isdigit():
        labels[int(pair[0])] = pair[1].strip()
      else:
        labels[row_number] = pair[0].strip()
  return labels


def set_input_tensor(interpreter, image):
  """Sets the input tensor."""
  tensor_index = interpreter.get_input_details()[0]['index']
  input_tensor = interpreter.tensor(tensor_index)()[0]
  input_tensor[:, :] = image


def get_output_tensor(interpreter, index):
  """Returns the output tensor at the given index."""
  output_details = interpreter.get_output_details()[index]
  tensor = np.squeeze(interpreter.get_tensor(output_details['index']))
  return tensor


def detect_objects(interpreter, image, threshold):
  """Returns a list of detection results, each a dictionary of object info."""
  set_input_tensor(interpreter, image)
  interpreter.invoke()

  # Get all output details
  boxes = get_output_tensor(interpreter, 0)
  classes = get_output_tensor(interpreter, 1)
  scores = get_output_tensor(interpreter, 2)
  count = int(get_output_tensor(interpreter, 3))

  results = []
  for i in range(count):
    if scores[i] >= threshold:
      result = {
          'bounding_box': boxes[i],
          'class_id': classes[i],
          'score': scores[i]
      }
      results.append(result)
  return results


def free_up_space():
  print('USB has less than 100MB!', shutil.disk_usage(storage_location).free)


detected_dic = {}
def process_objects(results, labels, camera):
  """Draws the bounding box and label for each object in the results."""
  for obj in results:
    if (obj['class_id'] in range(0, 9) or obj['class_id'] in range(15, 25)):
      if labels[obj['class_id']] not in detected_dic.keys():
        detected_dic[labels[obj['class_id']]] = 100
        #print('time', labels[obj['class_id']], int(obj['score']*100))
        try:
          disk_free = shutil.disk_usage(storage_location).free
          csvlog.writerow([datetime.now(), CPUTemperature().temperature, disk_free])
          if disk_free < 100*1024*1024: #100MB
            free_up_space()
          os.makedirs(datetime.now().strftime(storage_location+'%Y/%m/%d'), exist_ok=True)
          camera.capture(storage_location+
                         datetime.now().strftime('%Y/%m/%d/%H%M%S.%f ')+
                         labels[obj['class_id']]+
                         ' '+
                         str(int(obj['score']*100))+
                         '.jpeg')
        except Exception as e:
          print('log: camera.capture', e)
    for key, value in list(detected_dic.items()):
      detected_dic[key] = value-1
      if value == 1:
        del detected_dic[key]


def main():
  parser = argparse.ArgumentParser(
      formatter_class=argparse.ArgumentDefaultsHelpFormatter)
  parser.add_argument(
      '--model', help='File path of .tflite file.', required=True)
  parser.add_argument(
      '--labels', help='File path of labels file.', required=True)
  parser.add_argument(
      '--threshold',
      help='Score threshold for detected objects.',
      required=False,
      type=float,
      default=0.6)
  args = parser.parse_args()

  labels = load_labels(args.labels)
  interpreter = Interpreter(args.model)
  interpreter.allocate_tensors()
  _, input_height, input_width, _ = interpreter.get_input_details()[0]['shape']

  with picamera.PiCamera(resolution=(CAMERA_WIDTH, CAMERA_HEIGHT), framerate=15) as camera:
    camera.rotation=180
    camera.start_preview()
    print('Running')
    try:
      stream = io.BytesIO()
      for _ in camera.capture_continuous(stream, format='jpeg', use_video_port=True, resize=(input_width,input_height)):
        stream.seek(0)
        try:
          image = Image.open(stream)
        except Exception as e:
          print(e)
          print('test: stream.truncate()')
          stream.truncate() #test
          continue
        results = detect_objects(interpreter, image, args.threshold)

        process_objects(results, labels, camera)

        stream.seek(0)
        stream.truncate()

    finally:
      print('finally')
      camera.stop_preview()


if __name__ == '__main__':
  main()
