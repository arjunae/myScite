/*
Java Class Sample - showing the use of FileStreams    
*/
import java.io.*;
public class test_java {

   public static void main (String args[]) throws IOException {  
      FileInputStream inFile  = null;
      FileOutputStream outFile = null;
      System.out.println("Read SciTEUser.properties" + " and " + "write the bytestream to Folder data."); 
   
      try {
         inFile  = new FileInputStream("../../SciTEUser.properties");
         outFile = new FileOutputStream("data/sciteuser.properties");
         System.out.println("inFile's length: " + inFile.available() +" Bytes.");       
         int pos;
         while ((pos = inFile .read()) != -1) 
            outFile.write(pos);
      } finally {
         if (inFile  != null)    
            inFile .close();
         if (outFile != null) {
            System.out.println("OK: inFile's content has been written to Folder Data.");
            outFile.close();
         }
      }
   }
}