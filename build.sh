#!/bin/bash

as -o "exec.o" "exec.s"
ld -o "exec" "exec.o"
