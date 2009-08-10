using GLib;
using Vala;

//TODO: rename ".implicits" to ".markuphints"
//TODO: rename "constructor" to "creation method"

/**
 * Contains parameters for constructors and add methods of a given Class/Interface, 
 * along with their default values if present
 */
public class Gtkaml.MarkupImplicits {
	public string target;
	
	/** the class/interface after resolving */
	public TypeSymbol symbol; //TODO use this
	
	/** cache of the base markup implicits */
	Gee.List<weak MarkupImplicits> base_implicits_cache; //of course is not used, it's a cache:P
	
	private static string ADD = "add-";
	private static string NEW = "new-";
	
	/* maps for directly navigating to a given constructor/add method*/
	private Gee.Map<string, Gee.List<Pair<string,string?>>> implicit_map;
	
	/* lists for preserving .implicits file order */
	private Gee.List<Pair<string, Gee.List<Pair<string, string?>>>> implicit_list;
	
	public MarkupImplicits (string target) {
		this.target = target;
		this.implicit_map = new Gee.HashMap<string, Gee.List<Pair<string,string?>>> (str_hash, str_equal);
		this.implicit_list = new Gee.ArrayList<Pair<string, Gee.List<Pair<string, string?>>>> ();
	}
	
	/* adding a constructor or an add method */
	
	private void add_implicit (string implicit_name, string type) {
		var full_implicit_name = type + implicit_name;
		if (!implicit_map.contains (full_implicit_name)) {
			var parameters_list = new Gee.ArrayList<Pair<string, string?>> ();
			implicit_map.set (full_implicit_name, parameters_list);
			implicit_list.add (new Pair<string, Gee.List<Pair<string, string?>>> (full_implicit_name, parameters_list));
		}
	}
	
	public void add_implicit_constructor (string constructor_name) {
		add_implicit (constructor_name, MarkupImplicits.NEW);
	}
	
	public void add_implicit_add (string implicit_add_name) {
		add_implicit (implicit_add_name, MarkupImplicits.ADD);
	}
	
	/* adding parameters to constructor or add method */
	
	private bool add_implicit_parameter (string implicit_name, string type, string parameter, string? default_value) {
		var implicit_full_name = type + implicit_name;
		var parameters = implicit_map.get (implicit_full_name);
		
		if (parameters == null) {
			return false;
		}	
		
		parameters.add (new Pair<string, string?> (parameter, default_value));
		return true;
	}
		
	public bool add_constructor_parameter (string constructor_name, string parameter, string? default_value) {
		return add_implicit_parameter (constructor_name, NEW, parameter, default_value);
	}
	
	public bool add_implicit_add_parameter (string implicit_add_name, string parameter, string? default_value) {
		return add_implicit_parameter (implicit_add_name, ADD, parameter, default_value);
	}
}

public class Gtkaml.Pair<K,V> {
	public K name;
	public V value;
	public Pair (K# name, V# value) {
		this.name = #name;
		this.value = #value;
	}
}
