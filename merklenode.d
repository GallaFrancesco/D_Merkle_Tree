import std.string;
import std.stdio;
import std.conv;
import utils_hash;
import std.digest.sha;

class Node {

	private char[64] _hash;
	private Node _parent;
	private Node _left;
	private Node _right;
	private bool _leaf;
	private bool _root;
	private bool _duplicate;

	// structural functions
	@property inout(Node) left() inout {
		return _left;
	}

	@property inout(Node) right() inout {
		return _right;
	}

	@property inout(Node) parent() inout {
		return _parent;
	}

	// set a node as the parent
	// useful for bottom-up building
	// (leaf upwards)
	@property Node parent(Node n) {
		return _parent = n;
	}

	// overloads to create new left, right nodes
	@property Node left (Node n) {
		return _left = n;
	}

	@property Node right (Node n) {
		return _right = n;
	}

	// flag duplicate nodes
	@property bool duplicate () {
		return _duplicate;
	}

	@property bool duplicate (bool v) {
		return _duplicate = v;
	}

	// get the hash as a char array
	// TODO the hash should be decided, not forced to 64 bit
	@property string hash () {
		return cast(string)this._hash;
	}

	@property bool isLeafNode (){
		return _leaf;
	}

	@property bool isRoot (){
		return _root;	
	}

	abstract string verify () {
		return "";
	}
}

class LeafNode : Node {
	// the block id (unique)
	uint blockId;
	private ubyte[] data;	
	

	this (uint bId, ubyte[] d) {
		_leaf = true;
		data = d;
		duplicate = false;
		blockId = bId;
	}

	char[64] computeHash(Hash)() {
		_hash = produceHash!Hash(to!string(data), this.isLeafNode);
		return _hash;
	}

	override string verify () {
		auto h = cast(string) computeHash!SHA256();
		//writeln("Leaf "~h);
		return h;
 	}
}

class InternalNode : Node {
	// intialize the InternalNode node
	// the parent must be provided,
	// default is null for root
	this (Node l, Node r) {
		_leaf = false;
		_root = true;
		duplicate = false;
		if (parent !is null) {
			_parent = parent;
			_root = false;
		} else {
			_root = true;
		}
		this.left = l;
		this.right = r;
	}

	char[64] computeHash(Hash)(string lhash, string rhash) {
		// concatenate the two childrens' hashes into a string
		string data = cast(string)lhash ~ cast(string)rhash;
		// hash the string
		_hash = produceHash!Hash(data, false);
		return _hash;
	}

	override string verify () {
		// the node is not a leaf, recur on the subnodes
		auto h = cast(string) computeHash!SHA256(this.left.verify(), this.right.verify());
		//writeln("Internal: "~h);
		return h;
	}
}


unittest {
	// leaf class
	import std.random;
	import std.stdio;
	import std.digest.sha;

	char[1024] data;
	// randomly generate a data block
	for (uint i=0; i<1024; i++) {
		data[i] = cast(char) uniform (65, 91);
	}
	writeln("[TEST] data: " ~ data);

	// create a new LeafNode object with the data block
	// index is 0
	LeafNode l = new LeafNode (0);
	// compute its hash (TEST with SHA256)
	l.computeHash!SHA256(data);
	writeln("[TEST] " ~ l.hash());

	// different data block
	char[1024] ndata;
	for (uint i=0; i<1024; i++) {
		ndata[i] = cast(char) uniform (65, 91);
	}

	// test the new data against the old one
	writeln("[TEST] ndata: " ~ ndata);
	assert(!l.checkHash!SHA256(ndata));
}

unittest {
	import std.stdio;
	import std.digest.sha;
	import std.random;
	// internal class
	char[1024] dataL, dataR;
	// randomly generate a data block
	for (uint i=0; i<1024; i++) {
		dataL[i] = cast(char) uniform (65, 91);
		dataR[1023-i] = cast(char) uniform (65, 91);
	}

	// create a new LeafNode object with the data block
	// index is 0
	LeafNode l = new LeafNode (0, dataL);
	LeafNode r = new LeafNode (0, dataR);

	InternalNode i = new InternalNode();
	i.left(l);
	i.right(r);
	i.computeHash!SHA256();
	writeln ("[TEST] internal: " ~ i.hash);
}

