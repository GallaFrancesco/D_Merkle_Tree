import std.stdio;
import std.file;
import utils_hash;
import std.digest.sha;
import merklenode;

class MerkleTree {
	// number of blocks = length of leaves
	uint nblocks;
	Node[] leaves;
	ulong filesize;

	private InternalNode _root;
	private string _dirname;
	private string _merkleroot;

	this (string dirname) {
		// create the leaves
		// connect the tree
		// save the merkleroot (root.hash)
		_dirname = dirname;
		nblocks = 0;
		_build_tree();
	}

	// verify the hash computed matches the merkleroot stored
	bool verify_tree () {
		auto mroot = root.verify();
		if (mroot == merkleroot) {
			return true;
		} else {
			merkleroot = mroot;
			return false;
		}
	}
	// for debugging purposes, print all the nodes' hashes
	void print_tree (Node n) {
		writeln ("Node: "~ cast(string) n.hash);
		if (!n.leaf) {
			print_tree(n.left);
			print_tree(n.right);
		}
	}

// helper functions
	private void _build_tree () {
		_build_leaves();
		_connect_tree(leaves);
	}
	// TODO
	private uint _round_nblocks (ulong size) {
		size = size/1024; // we need KB
		uint res = cast(uint) size;
		writeln(res);
		return res; 
	}

	private void _build_leaves () {
		// open the file for reading
		auto f = File (_dirname, "r");
		filesize = f.size;
		nblocks = _round_nblocks(filesize);

		// read the file in chunks of 256 KB
		// append the buffer read to the array of leaves
		int id = 0;
		foreach (ubyte[] buf; f.byChunk(256*1024)) {
			leaves ~= new LeafNode(id++, buf);
			nblocks++;
		}

		// if the number of blocks is odd
		// duplicate last node
		// mark the duplicate as such
		if (nblocks % 2 != 0) {
			leaves ~= leaves[$-1];
			nblocks++;
			leaves[$-1].duplicate = true;
		}

		writeln (leaves.length);

	}

	// build the actual tree connecting leaves and internals
	private void _connect_tree (Node[] nodes) {
		// if we only have 1 element in nodes
		// we arrived at the root of the tree
		if (nodes.length == 1) {
			root = cast(InternalNode) nodes[0];
			merkleroot = root.hash;
			return;
		}

		// store the higher nodes to recur
		Node[] higherNodes;

		// each couple of leaves is linked
		// to an InternalNode parent
		for (int i=0; i<nodes.length; i+=2) {
			// create a new parent for the two nodes
			// set the nodes as left, right
			auto parent = new InternalNode(nodes[i], nodes[i+1]);

			// compute the hash on the two nodes
			// store it in the internal node
			parent.computeHash!SHA256(nodes[i].hash, nodes[i+1].hash);
			nodes[i].parent = parent;
			nodes[i+1].parent = parent;

			// append the node to the list of new nodes
			higherNodes ~= parent;
		}

		if (higherNodes.length % 2 != 0 && higherNodes.length != 1) { 
			higherNodes ~= higherNodes[$-1];
			higherNodes[$-1].duplicate = true;
		}


		writeln (higherNodes.length);
		_connect_tree(higherNodes);
	}

// properties
	@property InternalNode root() {
		return _root;
	}

	@property InternalNode root(InternalNode r) {
		return _root = r;
	}

	@property string merkleroot() {
		return _merkleroot;
	}

	@property string merkleroot(char[64] mr) {
		return _merkleroot = cast(string) mr;
	}

	@property string merkleroot(string mr) {
		return _merkleroot = mr;

	}
}

void main() {
	MerkleTree mkt = new MerkleTree ("/home/francesco/test");
	while (true) {
		writeln(mkt.verify_tree());
	}
	//mkt.print_tree(mkt.root);
}

