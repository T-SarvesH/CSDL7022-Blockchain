#Import Libraries
from typing import List
import hashlib
import networkx as nx
import matplotlib.pyplot as plt

# Defining a Merkel TreeNode
class Node:
    def __init__(self, left, right, value: str, content, is_copied=False) -> None:
        self.left: Node = left
        self.right: Node = right
        self.value = value
        self.content = content
        self.is_copied = is_copied

    @staticmethod
    def hash(val: str) -> str:
        return hashlib.sha256(val.encode('utf-8')).hexdigest()

    def __str__(self):
        return (str(self.value))

    def copy(self):
        """
        class copy function
        """
        return Node(self.left, self.right, self.value, self.content, True)


class MerkleTree:
    def __init__(self, values: List[str]) -> None:
        self.__buildTree(values)

    def __buildTree(self, values: List[str]) -> None:

        leaves: List[Node] = [Node(None, None, Node.hash(e), e)
                              for e in values]
        if len(leaves) % 2 == 1:
            # duplicate last elem if odd number of elements
            leaves.append(leaves[-1].copy())
        self.root: Node = self.__buildTreeRec(leaves)

    def __buildTreeRec(self, nodes: List[Node]) -> Node:
        if len(nodes) % 2 == 1:
            # duplicate last elem if odd number of elements
            nodes.append(nodes[-1].copy())
        half: int = len(nodes) // 2

        if len(nodes) == 2:
            return Node(nodes[0], nodes[1], Node.hash(nodes[0].value + nodes[1].value), nodes[0].content+"+"+nodes[1].content)

        left: Node = self.__buildTreeRec(nodes[:half])
        right: Node = self.__buildTreeRec(nodes[half:])
        value: str = Node.hash(left.value + right.value)
        content: str = f'{left.content}+{right.content}'
        return Node(left, right, value, content)

    def printTree(self) -> None:
        self.__printTreeRec(self.root)

    def __printTreeRec(self, node: Node) -> None:
        if node != None:
            if node.left != None:
                print("Left: "+str(node.left))
                print("Right: "+str(node.right))
            else:
                print("Input")

            if node.is_copied:
                print('(Padding)')
            print("Value: "+str(node.value))
            print("Content: "+str(node.content))
            print("")
            self.__printTreeRec(node.left)
            self.__printTreeRec(node.right)

    def getRootHash(self) -> str:
        return self.root.value

    def visualizeTree(self) -> None:

        #We basically use BFS to establish the edges correctly for each of the nodes 
        digraph = nx.DiGraph()
        queue : List[Node] = []
        queue.append(self.root)

        while len(queue) > 0:
            length = len(queue)
            for i in range(length):
                node = queue.pop(0)

                node_label = f"Hash: {node.value[:7]}...\nContent: {node.content}"
                if node.is_copied:
                    node_label += "\n(Padding)"
                
                # Add node with its full value as identifier, and descriptive label
                digraph.add_node(node.value, label=node_label)

                if node.left:
                    digraph.add_edge(node.value, node.left.value)
                    queue.append(node.left)

                if node.right:
                    digraph.add_edge(node.value, node.right.value)
                    queue.append(node.right)
        
        plt.figure(figsize=(20, 15)) # Adjusted figure size for better aspect ratio

        try:
            pos = nx.drawing.nx_pydot.graphviz_layout(digraph, prog='dot')
        except ImportError:
            print("Warning: pydot or Graphviz not found. Falling back to spring_layout. "
                  "Install Graphviz and 'pip install pydot' for better tree layouts.")
            pos = nx.spring_layout(digraph)
        # --- END OF IMPORTANT CHANGE ---

        # Draw the graph
        nx.draw(digraph, pos,
                with_labels=True,
                labels=nx.get_node_attributes(digraph, 'label'), # Use the 'label' attribute for display
                node_size=6000, # Increased node size to accommodate more text
                node_color='lightblue',
                font_size=8,   # Adjusted font size if needed
                font_weight='bold', # Makes labels more readable
                arrows=True,
                arrowsize=20) # Make arrows more prominent

        plt.title("Merkle Tree Visualization (Hierarchical Layout)", fontsize=16)
        plt.show()

        #Implementing a queue
def mixmerkletree():

    n: int = int(input("Enter number of elms: "))
    elms: List[str] = []

    # So that n is even
    n = n + (n%2)

    while n:

        elms.append(input("Enter elm: "))
        n-=1
    
    print("Inputs: ")
    print(*elms, sep=" | ")
    print("")

    mtree = MerkleTree(elms)

    print("Root Hash: "+mtree.getRootHash()+"\n")

    mtree.printTree()
    mtree.visualizeTree()

if __name__ == "__main__":
    print("------MERKEL TREE IMPLEMENTATION SARVESH----")
    mixmerkletree()