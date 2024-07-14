#!/bin/bash
directory="tests/result"

odin test tests -all-packages -out:"$directory/test"
