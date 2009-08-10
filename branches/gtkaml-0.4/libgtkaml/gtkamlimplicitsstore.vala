using GLib;
using Vala;

/**
 * stores a map between .implicits symbols like [Gtk.Window] and their MarkupImplicits definitions
 */
public class Gtkaml.ImplicitsStore {
	public Gee.Map<string, MarkupImplicits> implicits;
	public CodeContext context;

	public ImplicitsStore (CodeContext context) {
		this.context = context;
		implicits = new Gee.HashMap<string, MarkupImplicits> (str_hash, str_equal);
	}

	public void parse () {
		//TODO: use our own folder?
		foreach (var source_file in context.get_source_files ()) {
			if (source_file.external_package) {
				var filename = source_file.filename.replace (".vapi", ".implicits");
				#if DEBUGIMPLICITS
				stderr.printf ("checking if '%s' file exists.. ", filename);
				#endif
				if (FileUtils.test (filename, FileTest.EXISTS))  {
					#if DEBUGIMPLICITS
					stderr.printf ("yes\n");
					#endif
					parse_package (filename);
				} else {
					#if DEBUGIMPLICITS
					stderr.printf ("no\n");
					#endif
				}
			}
		}
	}
	
	public void determine_creation_method (MarkupResolver markup_resolver, MarkupClass markup_class) {
		MarkupImplicits markup_implicits = implicits.get (markup_class.get_full_name ());
		//TODO: needs
		//...
	}
	
	void parse_package (string package_filename) {
		KeyFile key_file = new KeyFile ();
		try {
			key_file.load_from_file (package_filename, KeyFileFlags.NONE);		
		} catch (KeyFileError e) {
			context.report.warn (null, "There was an error parsing %s as implicits file".printf (package_filename));
			return;
		}
		
		foreach (var symbol_fullname in key_file.get_groups ()) {
			var symbol_implicits = parse_symbol (ref key_file, symbol_fullname);
			implicits.set (symbol_fullname, symbol_implicits);
		}
	}
	
	MarkupImplicits parse_symbol (ref KeyFile key_file, string symbol_fullname) {
		#if DEBUGIMPLICITS
		stderr.printf ("parsing implicits group '%s'\n", symbol_fullname);
		#endif
		
		var symbol_implicits = new MarkupImplicits (symbol_fullname);

		string [] keys = key_file.get_keys (symbol_fullname); //the group comes from get_groups ()

		string implicit_name;		
		foreach (string key in keys) {
			#if DEBUGIMPLICITS
			stderr.printf ("definition is '%s' and is interpreted as ", key);
			#endif
			
			if (key.has_prefix ("new")) { //constructor parameters
				
				if (key.has_prefix ("new.")) 
					implicit_name = key.substring (4);
				else
					implicit_name = "";

				#if DEBUGIMPLICITS
				stderr.printf ("creation method '%s' with the following parameters:\n", implicit_name);
				#endif
				
				symbol_implicits.add_implicit_constructor (implicit_name);
				
				foreach (var parameter in key_file.get_string_list (symbol_fullname, key)) {
					string parameter_name = parameter.split ("=",2)[0];
					string parameter_value = parameter.split ("=",2)[1];
					#if DEBUGIMPLICITS
					stderr.printf ("\t'%s'='%s'\n", parameter_name, parameter_value);
					#endif
					symbol_implicits.add_constructor_parameter (implicit_name, parameter_name, parameter_value);
				}
					
			} else if (key.has_prefix ("add")) { //add method
			
				if (key == "adds") { //add method listing
					#if DEBUGIMPLICITS
					stderr.printf ("add method listing with the following methods:\n");
					#endif
					foreach (string add in key_file.get_string_list (symbol_fullname, key)) {
						#if DEBUGIMPLICITS
						stderr.printf ("\t'%s'\n", add);
						#endif
						symbol_implicits.add_implicit_add (add);
					}
				
				} else if (key[3] == '.') { //add method parameters
					implicit_name = key.substring (4);
					#if DEBUGIMPLICITS
					stderr.printf ("add method '%s' with the following parameters:\n", implicit_name);
					#endif
					foreach (var parameter in key_file.get_string_list (symbol_fullname, key)) {
						string parameter_name = parameter.split ("=",2)[0];
						string parameter_value = parameter.split ("=",2)[1];
						#if DEBUGIMPLICITS
						stderr.printf ("\t'%s'='%s'\n", parameter_name, parameter_value);
						#endif
						if (!symbol_implicits.add_implicit_add_parameter (implicit_name, parameter.split ("=",2)[0], parameter.split ("=",2)[1]))
							context.report.warn (null, "Add method %s not listed in [%s] implicits 'adds' ".printf (implicit_name, symbol_fullname)); 
					}	
				} else {
					context.report.warn (null, "Unknown '%s' key in [%s] section".printf (key, symbol_fullname));
				}
			} else {
				context.report.warn (null, "Unknown '%s' key in [%s] section".printf (key, symbol_fullname));
			}
		}
		
		return symbol_implicits;
	}
	

}
