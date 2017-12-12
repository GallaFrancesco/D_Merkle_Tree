import std.stdio;
import std.file;
import std.math;
import utils_hash;
import std.digest.sha;
import merklenode;

class MerkleTree {
	// number of blocks = length of leaves
	ulong nblocks;
	// block size, default is 256KB
	ulong bsize = 256*1024;
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

	// rebuild the leaves
	// check if they correspond to the stored ones
	// if not, update the block(s) that differ and verify
	void update_tree () {
		Node[] oldLeaves = leaves;
		leaves = _build_leaves(_dirname);

		// TODO fix workaround
		if (nblocks > oldLeaves.length) {
			_connect_tree(leaves);
			return;
		}

		for (int i=0; i<nblocks; i++) {
			auto node = cast (LeafNode) leaves[i];
			node.computeHash!SHA256();

			if (i < oldLeaves.length) {
				// if exist a corresponding old leaf
				// check if the hashes match
				if (node.hash != oldLeaves[i].hash) {
					// if the hashes don't match
					// the node needs to be updated
					// the tree must be verified again
					_update_block(node, oldLeaves[i]);
					writeln ("updated a node");
				}
			}
		}
	}

	bool verify_file (string dir, string mroot) {
		Node[] l = _build_leaves(dir);

		if (mroot == merkleroot) {
			return true;
		}

		if (l.length != nblocks) {
			return false;
		}

		for (int i=0; i<nblocks; i++) {
			auto node = cast (LeafNode) l[i];
			node.computeHash!SHA256();

			if (node.hash != leaves[i].hash) {
				return false;
			}
		}

		return true;
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
	private void _update_block (Node newNode, Node oldNode) {
		// substitute the new node to the old one in the tree
		// then update the hashes
		auto parent = oldNode.parent;

		if (oldNode == parent.right) {
			parent.right = newNode;
		} else {
			parent.left = newNode;
		}
		newNode.parent = parent;

		// update hashes
		_recompute (newNode);
	}

	private void _recompute (Node n) {
		// compute the hash of the node
		if (n.leaf) {
			auto node = cast (LeafNode) n;
			node.computeHash!SHA256();
		} else {
			auto node = cast (InternalNode) n;
			node.computeHash!SHA256(node.left.hash, node.right.hash);
		}

		if (!n.root) {
			// recursively compute the parents
			// until the root is found, then exit
			_recompute(n.parent);
		}
	}

	private void _build_tree () {
		leaves = _build_leaves(_dirname);
		_connect_tree(leaves);
	}

	// round the number of blocks to the next power of 2
	// then adapt the blocksize to match the number of blocks
	private void _round_nblocks (ulong sz) {
		real size = cast (real) sz;
		real nb = size / (256*1024);

		auto nbReal = nextPow2 (nb);
		bsize = cast (ulong) ceil (size / nbReal);
		nblocks = cast (ulong) nbReal;
	}

	private Node[] _build_leaves (string filename) {
		// open the file for reading
		// adapt the block size so that the number of blocks is a power of 2
		Node [] leav;
		auto f = File (filename, "r");
		filesize = f.size;
		_round_nblocks(filesize);
		// read the file in chunks of [bsize]
		// append the buffer read to the array of leav
		int id = 0;
		foreach (ubyte[] buf; f.byChunk(bsize)) {
			leav ~= new LeafNode(id++, buf);
		}
		writeln (leav.length);
		return leav;
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
	import core.thread;
	import core.time;
	auto mkt = new MerkleTree ("/home/francesco/test");
	mkt.verify_tree();
	// check for changes in the file
	//mkt.update_tree();
	// check if a provided file is equal to the one stored
	auto mkt2 = new MerkleTree("/home/francesco/test2");
	mkt2.verify_tree();
	writeln(mkt.verify_file("/home/francesco/test2", mkt2.merkleroot));
}

