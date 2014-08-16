grasky = window.grasky ?= {}

class grasky.GraphGenerator
  NAMES = ['Bella',
           'Edward',
           'Jacob',
           'Carlisle',
           'Esme',
           'Alice',
           'Emmett',
           'Rosalie',
           'Jasper',
           'Renesmee',
           'James',
           'Victoria',
           'Laurent',
           'Riley',
           'Bree',
           'Aro',
           'Caius',
           'Marcus',
           'Jane',
           'Alec',
           'Demetri',
           'Felix',
           'Heidi',
           'Leah',
           'Seth']
  
  EDGES = ['Siblings',
           'Friends',
           'Enemies',
           'Co-workers',
           'Allies',
           'Teammates',
           'Associates',
           'Roommates',
           'Flatmates',
           'Partners',
           'Co-owners',
           'Lovers',
           'In bloodpact']

  gilbertGraph: (graph, count, p) ->
    names = (NAMES[i] for i in [0...count])
    edges = []
    for i in [0...count]
      for j in [i + 1...count]
        if Math.random() < p
          edges.push
            nodes: [i, j]
            label: EDGES[edges.length % EDGES.length]
    addToGraph graph, names, edges

  addToGraph = (graph, names, edges) ->
    for name, i in names
      graph.addNode i, name
    for edge, i in edges
      graph.addEdge edge.nodes..., edge.label, i
