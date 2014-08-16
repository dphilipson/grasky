grasky = window.grasky ?= {}

class grasky.LatticeLayout
  SPACING = 9

  getLayout: (nodeCount, edges) ->
    nodesPerRow = getNodesPerRow nodeCount
    upperCorner = getUpperCorner nodesPerRow
    positions = []
    for layer in [0...nodesPerRow]
      for i in [0..layer]
        for j in [0..layer]
          for k in [0..layer]
            if positions.length is nodeCount
              return positions
            else if i is layer or j is layer or k is layer
              positions.push getPosition(upperCorner, k, j, i)
    positions

  getNodesPerRow = (count) ->
    # Get the smallest number whose cube is at least count.
    i = 1
    while i * i * i < count
      i++
    i

  getUpperCorner = (nodesPerRow) ->
    displacement = -SPACING * (nodesPerRow - 1) / 2
    new THREE.Vector3 displacement, displacement, displacement
 
  getPosition = (upperCorner, xIndex, yIndex, zIndex) ->
    new THREE.Vector3 xIndex, yIndex, zIndex
        .multiplyScalar SPACING
        .add upperCorner
