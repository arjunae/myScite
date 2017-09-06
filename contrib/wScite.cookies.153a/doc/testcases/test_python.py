#
# simple python tracing supported via Debug Menu
#
# --- http://sebsauvage.net/python/snyppets/#getlinks1
import HTMLParser, urllib

class linkParser(HTMLParser.HTMLParser):
    def __init__(self):
        HTMLParser.HTMLParser.__init__(self)
        self.links = []
    def handle_starttag(self, tag, attrs):
        if tag=='a':
            self.links.append(dict(attrs)['href'])

htmlSource = urllib.urlopen("http://www.freedos.org/").read(200000)
p = linkParser()
p.feed(htmlSource)

for link in p.links:
	print (link)

# --------------------------------

def say(x):
	print (x)
	
def two(x,y):
	say(x)
	say(y)
	
two(10,20)
