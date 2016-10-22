# Compatible with GNU make and BSD make.

build:
	@ceylon compile

doc:
	@ceylon doc `ceylon version` --resource-folder=resources


run-test:
	@ceylon test `ceylon version`

test: build run-test

fat-jar:
	@ceylon fat-jar `ceylon version`

jar: build fat-jar
