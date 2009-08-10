using GLib;
using Vala;


public class Gtkaml.MarkupTemp : MarkupSubTag {
	
	public MarkupTemp (MarkupTag parent_tag, string tag_name, MarkupNamespace tag_namespace, SourceReference? source_reference = null)
	{
		base (parent_tag, tag_name, tag_namespace, source_reference);
	}
	
}
