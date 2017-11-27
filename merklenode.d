import std.string;
import std.conv;
import utils_hash;

private class Node {

	private char[64] _hash;
	private Node _parent;
	private Node _left;
	private Node _right;
	private bool duplicate;

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

	// get the hash as a char array
	// TODO the hash should be decided, not forced to 64 bit
	@property inout(char[64]) hash () inout {
		return this._hash;
	}

	// verify each subtree by
	// computing the hashes for every leaves
	// validating the hashes for each level
	// return true if the computed hash matches the previous stored one
	char[64] verify(Hash)() {
		if (this.isLeafNode) {
			return this.computeHash!Hash();
		}
		// if the node is not a leaf, recur on the subnodes
		return this.computeHash!Hash(this.left.verify(), this.right.verify());
	}
}

class LeafNode : Node {
	// the block id (unique)
	uint blockId;
	private ubyte[] _data;	

	this (uint bId, ubyte[] data) {
		_parent = parent;
		_data = data;
		duplicate = false;
		blockId = bId;

		computeHash();
	}

	void computeHash(Hash)() {
		_hash = produceHash!Hash(to!string(_data), this.isLeafNode);
	}

	@property bool isLeafNode() {
		return true;
	}
}

class InternalNode : Node {
	// the leaf hash
	private bool _isroot;

	// intialize the InternalNode node
	// the parent must be provided,
	// default is null for root
	this (Node l, Node r) {
		duplicate = false;
		if (parent !is null) {
			_parent = parent;
			_isroot = false;
		} else {
			_isroot = true;
		}
		this.left = l;
		this.right = r;
	}

	void computeHash(Hash)(Node l, Node r) {
		// concatenate the two childrens' hashes into a string
		string data = to!string(l.hash) ~ to!string(r.hash);
		// hash the string
		this._hash = produceHash!Hash(data, false);
	}

	@property bool isLeafNode() {
		return false;
	}
	@property bool isroot() {
		return this._isroot;
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

