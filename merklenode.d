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

