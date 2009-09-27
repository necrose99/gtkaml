using Vala;

/**
 * wrapper for Method and Signal.
 * Supports .name and .get_parameters
 */

public class Gtkaml.Callable {
	
	public Member member {get; private set;}
	
	public Callable (Member member) {
		this.member = member;
		assert (member is Vala.Signal || member is Method);
	}
	
	public Gee.List<FormalParameter> get_parameters ()
	{
		if (member is Method)
			return ((Method)member).get_parameters ();
		return ((Vala.Signal)member).get_parameters ();
	}
	
	public string name { get { return member.name; } }
}
