# EVOLVE!

# Imports
import parameters
import random

# Constants
HIDDEN_NODE_TYPES = ["Linear", "ReLu", "Sigmoid", "Memory"]

# Functions
def gene_str(from_node, to_node):
  return "{}, {}".format(from_node, to_node)

# Classies
class Node():
  def __init__(self, num, type):
    self.num = num
    self.type = type

  def __eq__(self, other):
    return self.num == other.num and self.type == other.type


  def __str__(self):
    return "{}, {}".format(self.num, self.type)


class Gene():
  def __init__(self, from_node, to_node, w, pool):
    self.from_node = from_node
    self.to_node = to_node
    self.weigth = w
    self.pool = pool
    self.id = pool.id_gene(from_node, to_node)


  def __eq__(self, other):
    return self.from_node == other.from_node and self.to_node == other.to_node


  def __str__(self):
    return "{}, {}".format(self.from_node, self.to_node)



class Organism():
  def __init__(self, pool):
    self.pool = pool
    self.inputs = pool.inputs
    self.outputs = pool.outputs
    self.io_nodes = 1 + self.inputs + self.outputs
    self.nodelist = [Node(0, "bias")] + [Node(i, "input") for i in range(1, self.inputs+1)] +  [Node(i, "output") for i in range(self.outputs)]
    self.genes = []


  def add_node(self, type):
    if not type in HIDDEN_NODE_TYPES:
      raise Exception("invalid node type in add_node")
    num = self.nodelist[-1].num + 1
    new_node = Node(num, type)
    self.nodelist.append(new_node)
    return new_node

  def add_edge(self, from_node, to_node, weight):
    if not from_node in self.nodelist:
      raise Exception("from-node not in nodelist")
    if not to_node in self.nodelist:
      raise Exception("to-node not in nodelist")
    self.genes.append(Gene(from_node, to_node, weight, self.pool))

  # Turn an edge into a node w/ edges
  def mutate_node(self):
    # Check there is at least one edge
    if len(self.genes) == 0:
      return

    # Pick and edge
    edge = random.choice(self.genes)
    from_node = edge.from_node
    to_node = edge.to_node

    # Pick a node type
    type = random.choice(HIDDEN_NODE_TYPES)

    # Create the new node
    new_node = self.add_node(type)

    # Create connections
    self.add_edge(from_node, new_node, parameters.weight_init())
    self.add_edge(new_node, to_node, parameters.weight_init())

    # Remove old edge
    self.genes.remove(edge)



class Gene_List():
  def __init__(self):
    self.genes = {}
    self.n = 0

  def id_gene(self, from_node, to_node):
    hash = gene_str(from_node, to_node)
    if hash in self.genes:
      id = self.genes[hash]
    else:
      n += 1
      self.genes[hash] = n
      id = n
    return id



class Pool():
  def __init__(self, inputs, outputs, pop):
    self.inputs = inputs
    self.outputs = outputs
    self.organisms = [Organism(self) for _ in range(pop)]
    self.gene_list = Gene_List()


  def id_gene(self, from_node, to_node):
    return self.gene_list.id_gene()

