//* Hello3.cs
// arguments: A B C D
using System;
public class Hello3
{
   public static void Main(string[] args)
   {
   absolute=abs(-33);
   Console.WriteLine (absolute);
   Console.WriteLine("Hello, World!");
      Console.WriteLine("You entered the following {0} command line arguments:",
         args.Length );
      for (int i=0; i < args.Length; i++)
      {
         Console.WriteLine("{0}", args[i]); 
      }
   }
}
