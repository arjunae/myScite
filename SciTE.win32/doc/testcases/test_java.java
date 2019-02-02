/*
Java Class Sample - showing the use of FileStreams
*/
import java.io.*;
import java.util.Scanner;
public class test_java {

	public static void main(String args[]) throws IOException {
		FileInputStream inFile  = null;
		FileOutputStream outFile = null;
		Scanner scanner = new Scanner(System.in);
		System.out.println("Read SciTEUser.properties" + " and " + "write the bytestream to Folder data.");
		try {
			System.out.println("Type YES to proceed\n");
			String input = scanner.nextLine();
			if (!"YES".equals(input))
				return;
			inFile  = new FileInputStream("../../SciTEUser.properties");
			outFile = new FileOutputStream("data/sciteuser.properties");
			System.out.println("inFile's length: " + inFile.available() +" Bytes.");
			int pos;
			while ((pos = inFile .read()) != -1)
				outFile.write(pos);
			System.out.println("OK: inFile's content has been written to Folder Data.");
		} finally {
			if (inFile  != null)
				inFile .close();
			if (outFile != null)
				outFile.close();
		}
	}
}