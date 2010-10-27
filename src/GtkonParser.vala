/* gtkon parser -- Copyleft 2010 -- author: pancake<nopcode.org> */

int tok_idx = 0;
string tokens[64];
bool mustclose = false;
GtkonTokenType last_type = GtkonTokenType.INVALID;

private static void pushtoken (string token) {
	if (tok_idx>=tokens.length)
		error ("Cannot push more tokens");
	//print (">> [%d]=%s\n", tok_idx, token);
	tokens[tok_idx++] = token;
}

private static string poptoken () {
	if (tok_idx == 0)
		return "";
	//	error ("Cannot pop more tokens");
	//print ("<< [%d]=%s\n", tok_idx-1, tokens[tok_idx-1]);
	return tokens[--tok_idx];
}

public enum GtkonTokenType {
	CODE,
	CLASS,
	COMMENT_LINE,
	COMMENT_BLOCK,
	ATTRIBUTE,
	BEGIN,
	END,
	INVALID
}

// GtkonCompiler
// DataInputStream must be here
public char nextchar = 0;

[Compact]
public class GtkonToken {
	public bool quoted;
	public string str;
	public GtkonTokenType type;
	public DataInputStream? dis;

	private inline bool is_separator (uchar ch) {
		switch (ch) {
		case ' ':
		case '\t':
		case ',':
		case '\n':
		case '\r':
		case '\0':
			return true;
		}
		return false;
	}

	private uchar readchar() throws Error {
		uchar ch = nextchar;
		if (ch != 0) nextchar = 0;
		else ch = dis.read_byte ();
		return ch;
	}

	private bool skip_spaces() throws Error {
		var ch = 0;
		do { ch = readchar ();
		} while (is_separator (ch));
		return update (ch);
	}

	public GtkonToken(DataInputStream dis) throws Error {
		str = "";
		quoted = false;
		this.dis = dis;
		type = GtkonTokenType.CLASS;
		skip_spaces ();
		while (update (readchar ()));
	}

	public bool update (uchar ch) {
		if (quoted) {
			type = GtkonTokenType.ATTRIBUTE;
			str += "%c".printf (ch);
			if (str.has_suffix ("\"") && !str.has_suffix ("\\\"")) {
				return false;
			}
			return true;
		}
		switch (type) {
		case GtkonTokenType.COMMENT_LINE:
			if (ch == '\n' || ch == '\r') 
				return false;
			str += "%c".printf (ch);
			return true;
		case GtkonTokenType.COMMENT_BLOCK:
			str += "%c".printf (ch);
			if (str.has_suffix ("*/")) {
				str = str[0:str.length-2];
				return false;
			}
			return true;
		case GtkonTokenType.CODE:
			str += "%c".printf (ch);
			if (str.has_suffix ("}-")) {
				str = str[0:str.length-2];
				return false;
			}
			return true;
		default:
			/* do nothing here */
			break;
		}
		if (is_separator (ch)) {
			if (type == GtkonTokenType.ATTRIBUTE && (str.str ("=\"") != null)) {
				if (str.has_suffix ("\"") && !str.has_suffix ("\\\""))
					return false;
				/* continue */
				quoted = true;
			} else return false;
		}
		switch (ch) {
		case '"':
			quoted = true;
			break;
		case '$':
			type = GtkonTokenType.ATTRIBUTE;
			break;
		case ':':
			if (str.str ("=") == null)
				type = GtkonTokenType.CLASS;
			if (last_type == GtkonTokenType.CLASS)
				type = GtkonTokenType.ATTRIBUTE;
			break;
		case '=':
			type = GtkonTokenType.ATTRIBUTE;
			//mustclose = true;
			break;
		case '{':
			if (str == "-") {
				type = GtkonTokenType.CODE;
				str = "";
				return true;
			}
			if (str == "") {
				mustclose = true;
				type = GtkonTokenType.BEGIN;
				return false;
			}
			nextchar = '{';
			return false;
		case ';':
			if (str == "") {
				type = GtkonTokenType.END;
			mustclose = true;
				return false;
			}
			nextchar = ';';
			return false;
		case '}':
			type = GtkonTokenType.END;
			return false;
		}
		str += "%c".printf (ch);
		if (str == "//") {
			type = GtkonTokenType.COMMENT_LINE;
			str = "";
		} else
		if (str == "/*") {
			type = GtkonTokenType.COMMENT_BLOCK;
			str = "";
		}
		return true;
	}

	public string to_xml() {
		var eos = "";
		var bos = "";
		if (mustclose) {
			eos = ">";
			mustclose = false;
		}
		int max = tok_idx;
		if (type == GtkonTokenType.END)
			max--;
		for (int i = 0; i<max; i++)
			bos += "  ";
		switch (type) {
		case GtkonTokenType.CLASS:
			if (str != "") {
				pushtoken (str);
				bos += "<";
			}
			return bos+str+eos;
		case GtkonTokenType.COMMENT_BLOCK:
		case GtkonTokenType.COMMENT_LINE:
			return eos; //bos+"<!-- "+str+" -->\n";
		case GtkonTokenType.BEGIN:
			return ">\n";
		case GtkonTokenType.END:
			return eos+bos+"</"+poptoken ()+">\n";
		case GtkonTokenType.ATTRIBUTE:
			if (str[0] == '$')
				return " gtkaml:public=\"%s\"".printf (str[1:str.length]);
			if (str == "gtkon:root")
				return " xmlns:gtkaml=\"http://gtkaml.org/0.2\" xmlns=\"Gtk\"";
			var foo = str.split ("=", 2);
			if (foo.length != 2)
				error ("Missing value in attribute '%s'", str);
			var val = foo[1];
			if (val[0] == '"') {
				if (val[val.length-1] != '"')
					error ("Missing '\"' in attribute '%s'", str);
				val = val[1:val.length-1].replace ("\\\"", "\"");
			}
			return " "+foo[0]+"='"+val+"'"+eos;
		case GtkonTokenType.CODE:
			return bos+"<![CDATA[\n"+str+"\n"+bos+"]]>\n"+eos;
		case GtkonTokenType.INVALID:
			error ("Invalid token!");
		}
		return ""+eos; //<!-- XXX ("+str+") -->";
	}
}

public class GtkonParser {
	StringBuilder xmlstr = null;

	public GtkonParser() {
	}

	public void parse_file(string filename) {
		xmlstr = new StringBuilder ();
		var file = File.new_for_path (filename);

		if (!file.query_exists ())
			error ("File '%s' doesn't exist.", filename);

		GtkonToken? token = null;
		try {
			var dis = new DataInputStream (file.read ());
			for (;;) {
				token = new GtkonToken (dis);
				xmlstr.append (token.to_xml ());
				last_type = token.type;
			}
		} catch (Error e) {
			if (e.code != 0)
				error ("%s", e.message);
		}
	}

	public void to_file(string filename) {
		if (xmlstr == null)
			error ("no file parsed");
		var file = File.new_for_path (filename);
		try {
			var dos = new DataOutputStream (file.create (FileCreateFlags.NONE));
			dos.put_string ("<!-- automatically generated by gtkon -->\n");
			dos.put_string (xmlstr.str);
		} catch (Error e) {
			error ("%s", e.message);
		}
	}

	public string to_string() {
		return (xmlstr!=null)? xmlstr.str: "";
	}
}

#if MAIN
void main(string[] args) {
	if (args.length>1) {
		var gt = new GtkonParser ();
		foreach (unowned string file in args[1:args.length]) {
			if (!file.has_suffix (".gtkon"))
				error ("Unsupported file format for "+file+"\n");
			gt.parse_file (file);
			gt.to_file (file.replace (".gtkon", ".gtkaml"));
		}
	} else print ("gtkon [file.gtkon ...]\n");
}
#endif
