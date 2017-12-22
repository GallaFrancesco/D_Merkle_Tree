import std.digest.sha;
import std.digest.crc;
import std.digest.murmurhash;

// to select the hashing algorithm
string[] digestAlgorithms = [ "sha1", "sha256", "crc32", "mmhash"];

// returns a char[64] array containing the hash of the data block
// the function can produce a leaf hash (isLeaf == true)
// or an internal hash (isLeaf == false)
// the two hashes differ to avoid collisions
auto produceHash(Hash)(string str, bool isLeaf){
	string data;
	if (isLeaf) {
		data = 0 ~ str;
	} else {
		data = 1 ~ str;
	}
	// h is of type char[64]
	auto h = toHexString(digest!Hash(data));
	return h;
}

// compare the two hashes element by element
bool hashesEqual (string hash1, string hash2) {
	return hash1 == hash2;
}

unittest {	
    assert (hashesEqual(produceHash!SHA256("1111", true),"49E4B556E9E634D63266F6DDBD6BF18053882BD71BA20F09D8DD8A0DC2D4B67D")) ;
    assert (hashesEqual(produceHash!SHA256("1111", false),"F7FFF793C8AD73BB2F1BF70C3EB5745F8587312CCEDE17F0AF33AF0361D06913")) ;
}

/*** Testing Purpose (uncomment)***/
//void main () {}
