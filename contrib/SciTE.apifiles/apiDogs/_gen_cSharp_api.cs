//!csc -debug+ %file%
using System;
using System.IO;
using System.Collections.Generic;
using System.Reflection;
using System.Text.RegularExpressions;

class App {
	static Dictionary<string,string> dic=new Dictionary<string,string>();
	
	static void AnalyzeAssembly(Assembly a) {
		Regex re=new Regex(@".*`\d+");
		
		Type[] types=a.GetExportedTypes();
		foreach (Type t in types) {
			if (!re.IsMatch(t.Name)) {
				Console.WriteLine(t.Name);
				
				PropertyInfo[] api=t.GetProperties(BindingFlags.Instance|BindingFlags.Public|BindingFlags.Static);
				foreach (PropertyInfo pi in api)
					if (!re.IsMatch(pi.Name))
						Console.WriteLine("{0}",pi.Name);
					
				MethodInfo[] ami=t.GetMethods(BindingFlags.Instance|BindingFlags.Public|BindingFlags.Static);
				foreach (MethodInfo mi in ami)
					if (!re.IsMatch(mi.Name) && !mi.IsSpecialName) {
						Console.Write("{0}(",mi.Name);
						ParameterInfo[] apai=mi.GetParameters();
						bool bFirst=true;
						foreach (ParameterInfo  pai in apai) {
							if (!bFirst) Console.Write(",");
							Console.Write("{0} {1}",
								dic.ContainsKey(pai.ParameterType.FullName)?dic[pai.ParameterType.FullName]:pai.ParameterType.Name,
								pai.Name);
							bFirst=false;
						}
						Console.WriteLine(")");
					}
					
				EventInfo[] aei=t.GetEvents(BindingFlags.Instance|BindingFlags.Public|BindingFlags.Static);
				foreach (EventInfo ei in aei) {
					Console.WriteLine(ei.Name);
				}
			}
		}
	}
	
	[STAThread]
	static void Main(string[] args) {
		dic["System.Boolean"]="bool";
		dic["System.Byte"]="byte";
		dic["System.SByte"]="sbyte";
		dic["System.Char"]="char";
		dic["System.Decimal"]="decimal";
		dic["System.Double"]="double";
		dic["System.Single"]="float";
		dic["System.Int32"]="int";
		dic["System.UInt32"]="uint";
		dic["System.Int64"]="long";
		dic["System.UInt64"]="ulong";
		dic["System.Object"]="object";
		dic["System.Int16"]="short";
		dic["System.UInt16"]="ushort";
		dic["System.String"]="string";
		AppDomain.CurrentDomain.ReflectionOnlyAssemblyResolve+=delegate(object sender,ResolveEventArgs e) {
			return Assembly.ReflectionOnlyLoad(e.Name);
		};
		foreach (string s in args) {
			try {
				AnalyzeAssembly(Assembly.ReflectionOnlyLoadFrom(s));
			}
			catch (Exception ex) {
				Console.Error.WriteLine("Errore caricamento {0}:\n{1}",s,ex.Message);
			}
		}
	}
}
