using GLib;
using Vala;

public class Gtkaml.MarkupImplicits {
	public string target;
	public TypeSymbol symbol;
	
	/* maps for directly navigating to a given constructor/add method*/
	private Gee.Map<string, Gee.List<Pair<string,string>>> constructor_map;
	private Gee.Map<string, Gee.List<Pair<string,string>>> add_map;
	
	/* lists for preserving .implicits file order */
	private Gee.List<Pair<string, Gee.List<Pair<string, string>>>> constructor_list;
	private Gee.List<Pair<string, Gee.List<Pair<string, string>>>> add_list;
	
	public MarkupImplicits (string target) {
		this.target = target;
		this.constructor_map = new Gee.HashMap<string, Gee.List<Pair<string,string>>> (str_hash, str_equal);
		this.constructor_list = new Gee.ArrayList<Pair<string, Gee.List<Pair<string, string>>>> ();
		this.add_map = new Gee.HashMap<string, Gee.List<Pair<string,string>>> (str_hash, str_equal);
		this.add_list = new Gee.ArrayList<Pair<string, Gee.List<Pair<string, string>>>> ();
	}
	
	public void add_constructor (string constructor_name) {
		if (!constructor_map.contains (constructor_name)) {
			var parameters_list = new Gee.ArrayList<Pair<string, string>> ();
			constructor_map.set (constructor_name, parameters_list);
			constructor_list.add (new Pair<string, Gee.List<Pair<string, string>>> (constructor_name, parameters_list));
		}
	}
	
	public void add_constructor_parameter (string constructor_name, string parameter, string default_value) {
		var parameters = constructor_map.get (constructor_name);
		parameters.add (new Pair<string, string> (parameter, default_value));
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
