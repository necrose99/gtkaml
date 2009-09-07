using GLib;
using Vala;

/**
 * stores a map between *.markuphints symbols like [Gtk.Window] and their markup hints
 */
public class Gtkaml.MarkupHintsStore {
	public Gee.Map<string, MarkupHint> markup_hints;
	public CodeContext context;

	public MarkupHintsStore (CodeContext context) {
		this.context = context;
		markup_hints = new Gee.HashMap<string, MarkupHint> (str_hash, str_equal);
	}

	public void parse () {
		//TODO: use our own folder?
		foreach (var source_file in context.get_source_files ()) {
			if (source_file.external_package) {
				var filename = source_file.filename.replace (".vapi", ".markuphints");
				#if DEBUGMARKUPHINTS
				stderr.printf ("checking if '%s' file exists.. ", filename);
				#endif
				if (FileUtils.test (filename, FileTest.EXISTS))  {
					#if DEBUGMARKUPHINTS
					stderr.printf ("yes\n");
					#endif
					parse_package (filename);
				} else {
					#if DEBUGMARKUPHINTS
					stderr.printf ("no\n");
					#endif
				}
			}
		}
	}

	public Gee.List<SimpleMarkupAttribute> get_default_parameters (string full_type_name, Method m) {
		var parameters = new Gee.ArrayList<SimpleMarkupAttribute> ();
		var hint = markup_hints.get (full_type_name);
		if (hint != null) {
			Gee.List <Pair<string, string?>> parameter_hints = hint.get_creation_method_parameters (m.name);
			if (parameter_hints != null) {
				assert (parameter_hints.size == m.get_parameters ().size);
				//actual merge. with two parralell foreaches
				int i = 0;
				foreach (var formal_parameter in m.get_parameters ()) {
					assert ( i < parameter_hints.size );
					var parameter = new SimpleMarkupAttribute.with_type ( parameter_hints.get (i).name, parameter_hints.get (i).value, formal_parameter.parameter_type );
					parameters.add (parameter);
					i++;
				}
				return parameters;
			} 
		}	
		foreach (var formal_parameter in m.get_parameters ()) {
			var parameter = new SimpleMarkupAttribute.with_type ( formal_parameter.name, null, formal_parameter.parameter_type );
			parameters.add (parameter);
		}
		return parameters;
	}	
	
	void parse_package (string package_filename) {
		KeyFile key_file = new KeyFile ();
		try {
			key_file.load_from_file (package_filename, KeyFileFlags.NONE);		
		
			foreach (var symbol_fullname in key_file.get_groups ()) {
				var hints = parse_symbol (ref key_file, symbol_fullname);
				markup_hints.set (symbol_fullname, hints);
			}
		} catch (KeyFileError e) {
			context.report.warn (null, "There was an error parsing %s as markuphints file".printf (package_filename));
			return;
		}
	}
	
	MarkupHint parse_symbol (ref KeyFile key_file, string symbol_fullname) throws KeyFileError {
		#if DEBUGMARKUPHINTS
		stderr.printf ("parsing hint group '%s'\n", symbol_fullname);
		#endif
		
		var symbol_hint = new MarkupHint (symbol_fullname);

		string [] keys = key_file.get_keys (symbol_fullname); //the group comes from get_groups ()

		string hint_method_name;		
		foreach (string key in keys) {
			#if DEBUGMARKUPHINTS
			stderr.printf ("definition is '%s' and is interpreted as ", key);
			#endif
			
			if (key.has_prefix ("new")) { //creation parameters
				
				if (key.has_prefix ("new.")) 
					hint_method_name = key.substring (4);
				else
					hint_method_name = "new";

				#if DEBUGMARKUPHINTS
				stderr.printf ("creation method '%s' with the following parameters:\n", hint_method_name);
				#endif
				
				symbol_hint.add_creation_method (hint_method_name);
				
				foreach (var parameter in key_file.get_string_list (symbol_fullname, key)) {
					string parameter_name = parameter.split ("=",2)[0];
					string parameter_value = parameter.split ("=",2)[1];
					#if DEBUGMARKUPHINTS
					stderr.printf ("\t'%s'='%s'\n", parameter_name, parameter_value);
					#endif
					symbol_hint.add_creation_method_parameter (hint_method_name, parameter_name, parameter_value);
				}
					
			} else if (key.has_prefix ("add")) { //composition method
			
				if (key == "adds") { //composition method listing
					#if DEBUGMARKUPHINTS
					stderr.printf ("composition method list contains:\n");
					#endif
					foreach (string add in key_file.get_string_list (symbol_fullname, key)) {
						#if DEBUGMARKUPHINTS
						stderr.printf ("\t'%s'\n", add);
						#endif
						symbol_hint.add_composition_method (add);
					}
				
				} else if (key[3] == '.') { //composition method parameters
					hint_method_name = key.substring (4);
					#if DEBUGMARKUPHINTS
					stderr.printf ("add method '%s' with the following parameters:\n", hint_method_name);
					#endif
					foreach (var parameter in key_file.get_string_list (symbol_fullname, key)) {
						string parameter_name = parameter.split ("=",2)[0];
						string parameter_value = parameter.split ("=",2)[1];
						#if DEBUGMARKUPHINTS
						stderr.printf ("\t'%s'='%s'\n", parameter_name, parameter_value);
						#endif
						if (!symbol_hint.add_composition_method_parameter (hint_method_name, parameter_name, parameter_value))
							context.report.warn (null, "Composition method %s not listed in [%s]'s composition methods ".printf (hint_method_name, symbol_fullname)); 
					}	
				} else {
					context.report.warn (null, "Unknown '%s' key in [%s] section".printf (key, symbol_fullname));
				}
			} else {
				context.report.warn (null, "Unknown '%s' key in [%s] section".printf (key, symbol_fullname));
			}
		}
		
		return symbol_hint;
	}
	

}
