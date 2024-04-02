import os
import sys

if __name__ == '__main__':
	scriptPath = os.path.dirname(os.path.abspath( __file__ ))
	# print scriptPath
	sys.path.append(scriptPath)
	# print sys.path