using GLib;
using Vala;

/**
 * Contains parameters for creation and composition methods of a given Class/Interface, 
 * along with their default values if present
 */
public class Gtkaml.MarkupHint {
	/** the full symbol name of the target hinted symbol*/
	public string target;
	
	/** the target class/interface after resolving */
	//public TypeSymbol symbol; //TODO use this
	
	///** cache of the base markup hints */
	//Gee.List<weak MarkupHint> base_hint_cache; //of course is not used, it's a premature optimisation:P!
	
	private static string ADD = "add-"; //composition methods
	private static string NEW = "new-"; //creation methods
	
	/* maps for directly navigating to a given creation/composition method*/
	private Gee.Map<string, Gee.List<Pair<string,string?>>> hint_map;
	
	/* lists for preserving .markuphints file order */
	private Gee.List<Pair<string, Gee.List<Pair<string, string?>>>> hint_list;
	
	public MarkupHint (string target) {
		this.target = target;
		this.hint_map = new Gee.HashMap<string, Gee.List<Pair<string,string?>>> (str_hash, str_equal);
		this.hint_list = new Gee.ArrayList<Pair<string, Gee.List<Pair<string, string?>>>> ();
	}
	
	/* adding a creation or an composition method */
	
	private void add_hint (string hint_name, string type) {
		var full_hint_name = type + hint_name;
		if (!hint_map.contains (full_hint_name)) {
			var parameters_list = new Gee.ArrayList<Pair<string, string?>> ();
			hint_map.set (full_hint_name, parameters_list);
			hint_list.add (new Pair<string, Gee.List<Pair<string, string?>>> (full_hint_name, parameters_list));
		}
	}
	
	public void add_creation_method (string creation_method_name) {
		add_hint (creation_method_name, MarkupHint.NEW);
	}
	
	public void add_composition_method (string composition_method_name) {
		add_hint (composition_method_name, MarkupHint.ADD);
	}
	
	/* adding parameters to creation or composition method */
	
	private bool add_hint_parameter (string hint_method_name, string type, string parameter, string? default_value) {
		var hint_full_name = type + hint_method_name;
		var parameters = hint_map.get (hint_full_name);
		
		if (parameters == null) {
			return false;
		}	
		
		parameters.add (new Pair<string, string?> (parameter, default_value));
		return true;
	}
		
	public bool add_creation_method_parameter (string creation_method_name, string parameter, string? default_value) {
		return add_hint_parameter (creation_method_name, NEW, parameter, default_value);
	}
	
	public bool add_composition_method_parameter (string composition_method_name, string parameter, string? default_value) {
		return add_hint_parameter (composition_method_name, ADD, parameter, default_value);
	}
}

public class Gtkaml.Pair<K,V> {
	public K name;
	public V value;
	public Pair (owned K name, owned V value) {
		this.name = (owned)name;
		this.value = (owned)value;
	}
}
