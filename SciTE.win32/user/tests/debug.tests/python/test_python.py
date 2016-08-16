#
# simple python tracing supported via Debug Menu
# Press Ctrl-F5
#

import HTMLParser, urllib

class linkParser(HTMLParser.HTMLParser):
    def __init__(self):
        HTMLParser.HTMLParser.__init__(self)
        self.links = []

def say(x):
	print x
	
def two(x,y):
	say(x)
	say(y)
	
two(10,20)
