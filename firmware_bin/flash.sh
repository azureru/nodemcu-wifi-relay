#!/bin/bash
USB=/dev/cu.wchusbserial1420
./esptool.py --port $USB write_flash -fm dio -fs 32m 0x00000 ./nodemcu_integer_flash.bin
