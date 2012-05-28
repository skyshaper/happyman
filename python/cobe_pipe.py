#!/usr/bin/env python
import sys
from cobe.brain import Brain

if len(sys.argv) != 2:
	print "Usage: %s <brain>" % sys.argv[0]
	sys.exit(1)

brain = Brain(sys.argv[1])

while True:
	data = sys.stdin.readline().decode('utf-8')
	if len(data) == 0:
		break
	cmd, line = data.split(' ', 1)
	if cmd == 'learn':
		brain.learn(line)
	elif cmd == 'reply':
		reply = brain.reply(line)
		sys.stdout.write((reply + "\n").encode('utf-8'))
		sys.stdout.flush()
