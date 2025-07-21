import hashlib

#Implementing the class for MerkleTrees

class MerkleTree:
    def __init__(self, leaves):
        self.leaves = leaves

class MerkleTreeNode:
    def __init__(self, val, left, right):
        self.left = left
        self.right = right
        self.val = val
    
if __name__ == '__main__':
    pass