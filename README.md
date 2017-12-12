# Merkle Tree

A library implementing a Merkle Binary Tree data structure.
It aims to easily authenticate files by splitting them into blocks of arbitrary size (currently maxed at 256KB), loading the blocks into a binary tree which stores the hashes of the children nodes inside the parent nodes.
The blocks can be modified and the tree updated, providing a lightweight approach to file monitoring and transfer.

There's a lot of documentation regarding merkle trees online, starting from [wikipedia](https://en.wikipedia.org/wiki/Merkle_tree).

## Status of development

This is a work in progress, the library is currently able to load a file, verify the tree and update it, even though **insertion of additional blocks has yet to be implemented**.

### Current capabilities

* Load a file of arbitrary dimension inside the tree, adapting the block size so that the number of blocks is a power of 2.
* Verify single nodes (thus the subtree of which they are parent nodes), or the whole tree. In particular, the function `verify_tree` recomputes the merkle root by validating the whole structure.
* Update the tree: changing a file and calling `update_tree` results in a procedure which splits the new file in blocks, computes the new block hashes and compares them with the old ones. For each block with a different hash, an `_update_node` procedure is called, which substitutes the node and updates the tree recursively.

### To be implemented

* insertion of new nodes during tree update
* configuration options - digest function selection
* asynchronous computation of hashes, to speed up tree verification
