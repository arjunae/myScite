/*
 * This example demonstrates the way of creating a new file
 * by using File() constructor and file.createNewFile() method of File class.
 */

import java.io.File;
import java.io.IOException;

public class test_java
{
public static void main(String[] args)
{
	try{
		File file = new File("myfile.txt");
		if (file.createNewFile())
			System.out.println("Success!");
		else
			System.out.println
				("Error, file already exists.");
	}

	catch (IOException ioe) {
		ioe.printStackTrace();
	}
}
}
