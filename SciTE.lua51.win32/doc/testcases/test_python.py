#!/usr/bin/env python
#
# Make beautifier
#
# Author   : Philippe Fremy <pfremy@kde.org>
# 			 contributions from Adrian Thurston <adriant@ragel.ca>
# Version  : 1.3
# License  : Do whatever you want with this program!
# Warranty : None. Me and my program are not responsible for anything in the
# 			 world and more particularly on your computer.
#
# Usage : try --help

from string import *
import getopt
import sys
import os

import tempfile

#MAKEPROG = "make"
# Comment the previous line and uncomment the next line if you name your pretty-make.py 
# program 'make', to avoid recursion
MAKEPROG = "/usr/bin/make"

### Default values for command-line options:
SCREENWIDTH = 80 	# Fallback value, current value is deduced from resize
HIDE_LIBTOOL = 0
HIDE_WOPT = 1
HIDE_DOPT = 0
HIDE_IOPT = 0
HIDE_LOPT = 0
HIDE_FOPT = 0
HIDE_MOPT = 1
USE_STDIN = 0
USE_COLOR = 1
DEBUG_MAKE = 0

### Add more if I miss some!
COMPILER_NAME = ["cc", "gcc", "g++", "cpp", "c++", "gcc3", "ccache", "ccdist" ]

### Color codes:
#
#  The escape magic is:
#  <esc code>[<attribute>;<fg>;<bg>m
#  
#  <attribute> can be:
#  0 - Reset All Attributes (return to normal mode)
#  1 - Bright (Usually turns on BOLD)
#  2 - Dim
#  3 - Underline
#  5 - Blink
#  7 - Reverse
#  8 - Hidden
#  
#  <fg> is:     	<bg> is:    	  				
#  30 Black         40 Black                                        
#  31 Red           41 Red                                          
#  32 Green         42 Green                                        
#  33 Yellow        43 Yellow                                       
#  34 Blue          44 Blue                                         
#  35 Magenta       45 Magenta                                      
#  36 Cyan          46 Cyan                                         
#  37 White         47 White                                        
#  

colordict = { 
			"unknown": 		"[1;37;44m",
			"warnother": 	"[1;36m",
			"wopt": 		"[1;37m",
			"iopt": 		"[1;36m",
			"lopt": 		"[1;35m",
			"dopt": 		"[1;32m",
			"fopt": 		"[1;37m",
			"mopt": 		"[1;37m",
			"uic": 			"[1;33m",
			"moc": 			"[1;33m",
			"dcopidl": 		"[1;33m",
			"dcopidl2cpp": 	"[1;33m",
			"normal": 		"[0;37;49m" # disable bold when finishing
			#"normal": 		"[1;37;40m" # enable bold when finishing
			}

def processLine( words ):
	global HIDE_WOPT, HIDE_DOPT, HIDE_IOPT, HIDE_LOPT, HIDE_FOPT, HIDE_MOPT

	unknown = []
	hidden = [ words[0] ]
	includes = []
	defines = []
	warnopt = []
	warnother = []
	codegenopt = []
	archopt = []
	libopt = []

	# Rejoin args which seperated their value with space
	newWords = []
	joinWithLast = False
	for w in words[1:]:
		if joinWithLast:
			newWords[-1] = ' '.join([newWords[-1], w])
			joinWithLast = False
			continue
		if w in ["-I", "-D", "-W", "-l", "-L", "-f", "-m"]:
			joinWithLast = True
		newWords.append(w)

	for w in newWords:
		if   w[:2] == "-I" : includes.append( w )
		elif w[:2] == "-D" : defines.append( w )
		elif w[:2] == "-W" : warnopt.append( w )
		elif w[:2] == "-l" : libopt.append( w )
		elif w[:2] == "-L" : libopt.append( w )
		elif w == "-pedantic" : warnother.append( w )
		elif w == "-ansi" : warnother.append( w )
		elif w[:2] == "-f" : codegenopt.append( w )
		elif w == "-module" : unknown.append( w )
		elif w[:2] == "-m" : archopt.append( w )
		else: unknown.append( w )

	# result
	if HIDE_WOPT == 1 and len(warnopt)  > 0: hidden.append( "<-W>" )
	if HIDE_IOPT == 1 and len(includes) > 0: hidden.append( "<-I>" )
	if HIDE_DOPT == 1 and len(defines)  > 0: hidden.append( "<-D>" )
	if HIDE_LOPT == 1 and len(libopt)   > 0: hidden.append( "<-L>" )
	if HIDE_FOPT == 1 and len(codegenopt) > 0: hidden.append( "<-f>" )
	if HIDE_MOPT == 1 and len(archopt)  > 0: hidden.append( "<-m>" )

	unknown = hidden + warnother + unknown;
	formatOutput( unknown, "unknown", 1)
	if HIDE_WOPT == 0: formatOutput( warnopt, "wopt" )
	if HIDE_IOPT == 0: formatOutput( includes, "iopt" )
	if HIDE_DOPT == 0: formatOutput( defines, "dopt" )
	if HIDE_LOPT == 0: formatOutput( libopt, "lopt" )
	if HIDE_FOPT == 0: formatOutput( codegenopt, "fopt"  )
	if HIDE_MOPT == 0: formatOutput( archopt, "mopt"  )
	print

def outputline( line, colorcode ):
	global USE_COLOR, colordict

	if len( line ) == 0 : return
	if USE_COLOR: sys.stdout.write(colordict[ colorcode ])
	print line,
	if USE_COLOR: sys.stdout.write( colordict[ "normal" ] )
	print 

def formatOutput( words, colorcode, noindent = 0 ):
	global USE_COLOR, colordict

	if len(words) == 0: return

	if USE_COLOR: sys.stdout.write(colordict[ colorcode ])

	intro = " " * 4
	current = intro
	if noindent == 1:
		current = ""

	for w in words:
		if len(current) + len(w) + 1 >= SCREENWIDTH:
			print current,
			if USE_COLOR: sys.stdout.write(colordict[ colorcode ])
			print
			current = intro
		if len(current) > 1: current = current + " "
		current = current + w
	else:
		if len(current) > len( intro ): print current, 

	if USE_COLOR: sys.stdout.write( colordict[ "normal" ] )
	print


def usage():
	print "Make output beautifier. By default, run make and beautify its output.\nOptions are:"

	for o in opt_list:
		so, lo, have_arg, desc = o
		s = ''
		if len(so): s = s + so
		if len(so) and len(lo): s = s + ","
		if len(lo): s = s + lo
		if have_arg: s = s + "=<arg>"
		print "  ", s, "\t", desc

	print
	print "All unrecognised options are passed to make."
	print "Screen width is automatically deduced from the resize command"
	print "Use in your shell with: alias make=pretty-make.py"
	print "Use in vim with: set makeprg=pretty-make/pretty-make.py\ --no-colors"
	print "Use within a compilation with: export MAKE=pretty-make.py"
	print "Use within a configure with  : MAKE=pretty-make.py ./configure"
	print "Use always: create a symlink named make to pretty-make, and change the default MAKEPROG value in pretty-make.py to the real make program, to avoid recursion."
	print "You probably want to use colorgcc (it is a package in any modern distribution), and colorcvs: http://www.freekde.org/neil/colorcvs/"

opt_list = [	
	("-h", "--help", 		0, "\tThis description"),
	(""  , "--makeprog" , 	1, "Will run and parse the output of the program <arg> instead of 'make'."),
	(""  , "--stdin", 		0, "\tRead input from stdin. Don't launch make"),
	(""  , "--screenwidth",	1, "Output formatted for a screen of width <arg>"),
	(""  , "--",			0, "\t\tPass all the remainng arguments to make"),
	(""  , "--use-colors",	0, "Colored output"),
	(""  , "--no-colors",	0, "\tNon colored output"),
	(""  , "--hide-libtool", 	0,  "Displays just <libtool line> for all libtool lines"),
	(""  , "--show-libtool", 	0,  "Displays all libtool lines"),
	(""  , "--hide-wopt", 	0,  "Displays just <-W> for all -W options"),
	(""  , "--show-wopt", 	0,  "Displays all -W options"),
	(""  , "--hide-iopt", 	0,  "Displays just <-I> for all -I options"),
	(""  , "--show-iopt", 	0,  "Displays all -I options"),
	(""  , "--hide-dopt", 	0,  "Displays just <-D> for all -D options"),
	(""  , "--show-dopt", 	0,  "Displays all -D options"),
	(""  , "--hide-lopt", 	0,  "Displays just <-L> for all -l and -L options"),
	(""  , "--show-lopt", 	0,  "Displays all -l and -L options"),
	(""  , "--hide-fopt", 	0,  "Displays just <-f> for all -f options"),
	(""  , "--show-fopt", 	0,  "Displays all -f options"),
	(""  , "--hide-mopt", 	0,  "Displays just <-m> for all -m options"),
	(""  , "--show-mopt", 	0,  "Displays all -m options"),
	(""  , "--debug-make", 	0,  "Debug make command")
	]

def scan_args( args, option_list ):
	"""Returns a tuple (recognised_opts, remaining_args) from an arglist args
	and an option list option_list. 

	Option list format:
	(short option name, long option name, have extra argument, help text ).

	recognised_opts format: ("recognised option", "optional argument")

	All unrecognised argument are put into remaining_args
	"""
	
	remaining_args = []
	recognised_opts = []
	wait_arg = 0
	force_remaining = 0
	for i in range( len(args) ):
		arg = args[i]

		if force_remaining == 0 and arg == "--":
			force_remaining = 1
			continue

		if force_remaining == 1:
			remaining_args.append( arg )
			continue

		if wait_arg == 1:
			wait_arg = 0
			if arg[0] != "-":
				recognised_opts[-1:] = [ (recognised_opts[-1][0], arg) ]
				continue

		if arg.find("=") != -1:
			l = split( arg, "=" )
			key = l[0]
			val = l[1]
		else:
			key = arg
			val = ""

		for opt in opt_list:
			so, lo, have_arg, desc = opt
			if so == key or lo == key:
				recognised_opts.append( (key, val) )
				if have_arg == 1 and len(val) == 0:
					wait_arg = 1
				break
		else:
			remaining_args.append( arg )
	return ( recognised_opts,  remaining_args)
			

def guessScreenWidth():
	fname = tempfile.mktemp()
	os.system("resize > " + fname + " 2> /dev/null" )
	f = open(fname, "r")
	setColumn( f.readlines() )
	f.close()
	os.remove(fname)


def main():
	global USE_STDIN, MAKEPROG, SCREENWIDTH, COMPILER_NAME
	global HIDE_LIBTOOL, HIDE_WOPT, HIDE_DOPT, HIDE_IOPT, HIDE_LOPT
	global HIDE_FOPT, HIDE_MOPT, USE_COLOR, colordict, DEBUG_MAKE

	guessScreenWidth()
	#print "width : ", SCREENWIDTH

	opts, args = scan_args( sys.argv[1:], opt_list )

#	print opts, args

	for o, a in opts:
		if o == "--help" or o == "-h":
			usage()
			sys.exit()
		elif o == "--stdin":
			USE_STDIN = 1
		elif o == "--use-colors":
			USE_COLOR = 1
		elif o == "--no-colors":
			USE_COLOR = 0
		elif o == "--screenwidth":
			try:
				SCREENWIDTH = int(a)
			except ValueError:
				print "Bad screen width argument : '%s'" % a
				sys.exit(1)
			if SCREENWIDTH <= 5:
				print "Too small screen width : ", a
				sys.exit(1)
		elif o == "--makeprog":
			MAKEPROG = a
		elif o == "--hide-libtool":
			HIDE_LIBTOOL=1
		elif o == "--show-libtool":
			HIDE_LIBTOOL=0
		elif o == "--hide-wopt":
			HIDE_WOPT=1
		elif o == "--show-wopt":
			HIDE_WOPT=0
		elif o == "--hide-dopt":
			HIDE_DOPT=1
		elif o == "--show-dopt":
			HIDE_DOPT=0
		elif o == "--hide-iopt":
			HIDE_IOPT=1
		elif o == "--show-iopt":
			HIDE_IOPT=0
		elif o == "--hide-lopt":
			HIDE_LOPT=1
		elif o == "--show-lopt":
			HIDE_LOPT=0
		elif o == "--hide-fopt":
			HIDE_FOPT=1
		elif o == "--show-fopt":
			HIDE_FOPT=0
		elif o == "--hide-mopt":
			HIDE_MOPT=1
		elif o == "--show-mopt":
			HIDE_MOPT=0
		elif o == "--debug-make":
			DEBUG_MAKE = 1


	# be careful about arguments that include spaces.
	make_command = MAKEPROG
	if len(args): make_command += " '" + "' '".join(args) + "'"

	if DEBUG_MAKE:
		# log options of make
		log_file = open( "pretty-make.log", "w")
		log_file.write ( "\npretty-make: " +  `sys.argv[:]` + '\n' )
		log_file.write ( "\nmake: <<" + make_command + ">>\n" )
		log_file.close()

	if USE_STDIN == 1:
		src = sys.stdin
	else:
		proc =  os.popen( make_command )
		src = proc.fromchild
		# hop, src = os.popen( join( MAKEPROG ) )
		#hop, f = os.popen( 'python -c "import sys; sys.stderr.write(\'hoperr\\n\'); sys.stdout.write(\'hopout\\n\');"')

	try:
		l = src.readline()
		while len(l) :
			l = l[:-1]
			words = split( strip(l))
			words = map( strip, words)


			if len(words) == 0: 
				l = src.readline()
				continue

			first_word = words[0]
			first_word = first_word.split('/')[-1]
			first_word = first_word.split('=')[-1]

			if first_word == "/bin/sh":
				if HIDE_LIBTOOL == 1:
					print "<libtool line>"
				else:
					processLine( words )
			elif first_word.split('-')[-1] in COMPILER_NAME:
				processLine( words )
			elif first_word.find("bin/moc") != -1:
				outputline( l, "moc" )
			elif first_word.find("bin/uic") != -1:
				outputline( l, "uic" )
			elif first_word.find("/dcopidl") != -1:
				outputline( l, "dcopidl" )
			elif first_word.find("/dcopidl2cpp") != -1:
				outputline( l, "dcopidl2cpp" )
			else:
				print l

			sys.stdout.flush()
			l = src.readline()
	except KeyboardInterrupt:
		if USE_STDIN == 0:
			os.kill(proc.pid,15)
	src.close()


def setColumn( s ) :
	global SCREENWIDTH

	for i in s:
		#print "Parsing ", i
		if i.find("COLUMNS") == -1: continue
		i = replace(i, '=',' ')
		i = replace(i, "'",' ')
		i = replace(i, ';',' ')
		l = split( i )
		#print "List:", l
		for w in l:
			try:
				val = int(w)
				if val > 5:
					SCREENWIDTH = val
					return
			except ValueError:
				continue


if __name__ == "__main__":
    main()



