import std.string;
import std.conv;
import utils_hash;

private class Node {

	private char[64] _hash;
	private Node _parent;
	private Node _left;
	private Node _right;

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

	// create a new node
	@property Node left (Node newNode) {
		_left = newNode;
		if (newNode !is null) {
			newNode._parent = this;
		}
		return newNode;
	}

	@property Node right (Node newNode) {
		_right = newNode;
		if (newNode !is null) {
			newNode._parent = this;
		}
		return newNode;
	}

	@property inout(char[64]) hash () inout {
		return this._hash;
	}
}

class LeafNode : Node {
	// the block id (unique)
	uint blockId;
	// data chunk
	char[1024] data;

	this (uint bId, char[1024] d) {
		_parent = parent;
		this.blockId = bId;
		this.data = d;
	}

	void computeHash(Hash)() {
		this._hash = produceHash!Hash(to!string(this.data), this.isLeafNode);
	}

	// method to compare hashes for new data
	bool checkHash (Hash) (char[1024] ndata) {
		assert (ndata.length != 0 );

		// compute the new computeHash, then compare it to the previous one
		auto nhash = produceHash!Hash(to!string(ndata), true);

		if (hashesEqual(to!string(nhash), to!string(this._hash))) {
			return true;
		}
		return false;
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
	this () {
		if (parent !is null) {
			_parent = parent;
			_isroot = false;
		} else {
			_isroot = true;
		}
	}

	void computeHash(Hash)() {
		// concatenate the two childrens' hashes into a string
		string data = to!string(_left.hash) ~ to!string(_right.hash);
		// hash the string
		this._hash = produceHash!Hash(data, false);
	}

	@property bool isLeafNode() {
		return false;
	}
	@property bool isRoot() {
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
	LeafNode l = new LeafNode (0, data);
	// compute its hash (TEST with SHA256)
	l.computeHash!SHA256();
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

