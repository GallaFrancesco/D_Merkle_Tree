import std.stdio;
import std.file;
import merklenode;

class MerkleTree {
	// number of blocks = length of leafs
	uint nblocks;
	LeafNode[] leafs;

	private InternalNode _root;
	private string _dirname;
	private char[64] _merkleroot;


	this (string dirname) {
		_dirname = dirname;
		nblocks = 0;
		// create the leaves
		// connect the tree
		// save the merkleroot (root.hash)
		_build_tree();
	}

	// verify the hash computed matches the merkleroot stored
	bool verify_tree () {
		auto mroot = root.verify();
		if (mroot == merkleroot) {
			return true;
		}
		return false;
	}

// properties
	@property InternalNode root() {
		return _root;
	}

	@property InternalNode root(InternalNode r) {
		return _root = r;
	}

	@property char[64] merkleroot() {
		return _merkleroot;
	}

	@property char[64] merkleroot(char[64] mr) {
		return _merkleroot = mr;
	}

// helper functions
	private void _build_tree () {
		_build_leafs();
		_connect_tree();
	}

	private void _build_leafs () {
		// open the file for reading
		auto f = File (_dirname, "r");

		// read the file in chunks of 256 KB
		// append the buffer read to the array of leaves
		int id = 0;
		foreach (ubyte[] buf, f.byChunk(256*1024) {
			leafs ~= LeafNode(id++, buf);
			nblocks++;
		}

		// if the number of blocks is odd
		// duplicate last node
		// mark the duplicate as such
		if (nblocks % 2 != 0) {
			leafs ~= leafs[$-1];
			nblocks++;
			leafs[$-1].duplicate = true;
		}

	}

	// build the actual tree connecting leaves and internals
	private void _connect_tree (LeafNode[] nodes) {
		// if we only have 1 element in nodes
		// we arrived at the root of the tree
		if (nodes.length == 1) {
			root = nodes[0];
			merkleroot = root.hash;
			return;
		}

		// store the higher nodes to recur
		LeafNode[] higherNodes;

		// each couple of leaves is linked
		// to an InternalNode parent
		for (int i=0; i<nblocks; i+=2) {
			// create a new parent for the two nodes
			// set the nodes as left, right
			auto parent = InternalNode(nodes[i], nodes[i+1]);
			// compute the hash on the two nodes
			// store it in the internal node
			parent.computeHash!SHA256(nodes[i], nodes[i+1]);

			nodes[i].parent = parent;
			nodes[i+1].parent = parent;

			higherNodes ~= parent;
		}

		_connect_tree(higherNodes);
	}
}

void main() {}

