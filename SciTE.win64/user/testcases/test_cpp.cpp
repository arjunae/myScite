// go@ cmd /c g++ -g -O0  *.cpp -o $(FileName).exe &&  $(FileName).exe

/**
 *   ---== cpp lexer sample ==---
 *       -> @debugging: set a breakpoint with F9, and press CTRL-F5
 *       -> a strip showing the source file path will show up.
 *       -> change "test.cpp" to "test.cpp.exe" and you are set.
 */

#include <stdio.h>
#include <iostream>
#include <string>
#include <unistd.h>

void mySay(char *myString) {
	printf(myString);
}

int main() {
// Define some Vars to see in locals view
	char *test = (char *)"---------Test-------";
	std::string file_name = "test_cpp.cpp";
	std::string msg = "..file " + file_name;
	char *file_name_plain = (char *)file_name.c_str();
	char *msg_plain = (char *)msg.c_str();
	char *test2 = (char *)"--------Test-------";

// out a greeting,
	printf(msg_plain);

// check for a file
	int exists = access((char *)file_name.c_str(), F_OK);

// out result
	if (exists != -1)
		printf(" .. found - okay..");
	else
		printf(" .. not found - not okay..");

// hmm ..	finally...  lets do some -= ascii_art =- Tetris...
	mySay((char *)"\n	  ::: \n	::...::  \n");
}
