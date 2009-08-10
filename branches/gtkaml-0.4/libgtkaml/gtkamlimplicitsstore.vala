using GLib;
using Vala;

/**
 * stores a map between .implicits symbols like [Gtk.Window] and their ImplicitMarkup definitions
 */
public class Gtkaml.ImplicitsStore {
	public Gee.Map<string, MarkupImplicits> implicits;
	public CodeContext context;

	public ImplicitsStore (CodeContext context) {
		this.context = context;
		implicits = new Gee.HashMap<string, MarkupImplicits> (str_hash, str_equal);
	}

	public void parse () {
		foreach (var source_file in context.get_source_files ()) {
			if (source_file.external_package) {
				var	filename = source_file.filename.replace ("vapi$", "implicits");
				if (FileUtils.test (filename, FileTest.EXISTS))  {
					parse_package (filename);
				}
			}
		}
	}
	
	void parse_package (string package_filename) {
		KeyFile key_file = new KeyFile ();
		try {
			key_file.load_from_file (package_filename, KeyFileFlags.NONE);		
		} catch (KeyFileError e) {
			context.report.warn (null, "There was an error parsing %s".printf (package_filename));
			return;
		}
		
		foreach (var symbol_fullname in key_file.get_groups ()) {
			//I can write complicated jumpy code
			var symbol_implicits = parse_symbol (ref key_file, symbol_fullname);
			implicits.set (symbol_fullname, symbol_implicits);
		}
	}
	
	MarkupImplicits parse_symbol (ref KeyFile key_file, string symbol_fullname) {
		var symbol_implicits = new MarkupImplicits (symbol_fullname);

		string [] keys = key_file.get_keys (symbol_fullname); //the group comes from get_groups ()

		string implicit_name;		
		foreach (string key in keys) {
			if (key.has_prefix ("new")) { //constructor parameters
				
				if (key.has_prefix ("new.")) 
					implicit_name = key.substring (4);
				else
					implicit_name = "";

				symbol_implicits.add_implicit_constructor (implicit_name);
				
				foreach (var parameter in key_file.get_string_list (symbol_fullname, 	key))
					symbol_implicits.add_constructor_parameter (implicit_name, parameter.split ("=",2)[0], parameter.split ("=",2)[1]);
					
			} else if (key.has_prefix ("add")) { //add method
			
				if (key == "adds") { //add method listing
				
					foreach (string add in key_file.get_string_list (symbol_fullname, key))
						symbol_implicits.add_implicit_add (add);
				
				} else if (key[4] == '.') { //add method parameters
					implicit_name = key.substring (4);
					
					foreach (var parameter in key_file.get_string_list (symbol_fullname, key))
						if (!symbol_implicits.add_implicit_add_parameter (implicit_name, parameter.split ("=",2)[0], parameter.split ("=",2)[1]))
							context.report.warn (null, "Add method %s not listed in [%s] implicits 'adds' ".printf (implicit_name, symbol_fullname)); 
						
				} else {
					context.report.warn (null, "Unkown '%s' key in [%s] section".printf (key, symbol_fullname));
				}
			} else {
				context.report.warn (null, "Unkown '%s' key in [%s] section".printf (key, symbol_fullname));
			}
		}
		
		return symbol_implicits;
	}
	

}
