import std.string;
import std.stdio;
import std.conv;
import utils_hash;
import std.digest.sha;
import std.digest.crc;

class Node {

	private char[64] _hash;
	private Node _parent;
	private Node _left;
	private Node _right;
	private bool _leaf;
	private bool _root;
	private bool _duplicate;

// abstract == overriding forced
// verify the node's subtree hash, return it
	abstract string verify () {
		return "";
	}

// properties
	@property inout(Node) left() inout {
		return _left;
	}

	@property inout(Node) right() inout {
		return _right;
	}

	@property inout(Node) parent() inout {
		return _parent;
	}

// overloads to add new left, right, parent
	@property Node left (Node n) {
		return _left = n;
	}

	@property Node right (Node n) {
		return _right = n;
	}

	@property Node parent(Node n) {
		return _parent = n;
	}

// flag duplicate nodes
	@property bool duplicate () {
		return _duplicate;
	}

// set a node as duplicate
	@property bool duplicate (bool v) {
		return _duplicate = v;
	}

// get the hash as a char array
	@property string hash () {
		return cast(string)this._hash;
	}

	@property char[64] hash (char[64] h) {
		return this._hash = h;
	}

// LeafNode or InternalNode (faster way of discriminating)
	@property bool leaf (){
		return _leaf;
	}

	@property bool leaf (bool v) {
		return _leaf = v;
	}

	@property bool root (){
		return _root;
	}

	@property bool root (bool v) {
		return _root = v;
	}
}

class LeafNode : Node {
	// the block id (unique)
	uint blockId;
	private ubyte[] data;

	this (uint bId, ubyte[] d) {
		leaf = true;
		data = d;
		duplicate = false;
		blockId = bId;
	}

	string computeHash(Hash)() {
		hash = produceHash!Hash(to!string(data), leaf);
		return hash;
	}

	override string verify () {
		// this node is a leaf, thus return the computed hash
		auto h = computeHash!SHA256();
		return h;
 	}
}

class InternalNode : Node {
	// intialize the InternalNode node
	// the parent must be provided,
	// default is null for root
	this (Node l, Node r) {
		leaf = false;
		root = true;
		duplicate = false;
		if (parent !is null) {
			parent = parent;
			root = false;
		} else {
			root = true;
		}
		left = l;
		right = r;
	}

	string computeHash(Hash)(string lhash, string rhash) {
		// concatenate the two childrens' hashes into a string
		string data = lhash ~ rhash;
		// hash the string
		hash = produceHash!Hash(data, leaf);
		return hash;
	}

	override string verify () {
		// the node is not a leaf, recur on the subnodes
		auto h = computeHash!SHA256(left.verify(), right.verify());
		return h;
	}
}

unittest {
	ubyte[] input = [];
	auto l = new LeafNode(0, input);
	auto theHash = produceHash!SHA256(to!string(input), l.leaf); 

	assert (theHash == l.computeHash!SHA256());
}

unittest {
	ubyte[] input = [];
	auto l = new LeafNode(0, input);
	auto r = new LeafNode(1, input);

	auto internal = new InternalNode (l,r);

	LeafNode intL = cast(LeafNode) internal.left;
	LeafNode intR = cast(LeafNode) internal.right;

	assert (intL.blockId == l.blockId);
	assert (intR.blockId == r.blockId);
}

//** Testing Purpose (uncomment)**
//void main () {}
