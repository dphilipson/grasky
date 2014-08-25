$ ->
  canvas = $('#grasky-canvas')[0]
  graph = new grasky.Graph canvas
  new grasky.GraphGenerator().gilbertGraph graph, 25, 0.08
  graph.applyLayout new grasky.ForceDirectedLayout
  fixCanvas = ->
    canvas.style.width = window.innerWidth + 'px'
    canvas.style.height =  (window.innerHeight - $('#controls').height()) + 'px'
    graph.fixViewBounds()
  fixCanvas()
  $(window).resize fixCanvas

  $('#grasky-canvas').mousedown (e) ->
    e.preventDefault()

  $('#lattice-layout-item').click -> graph.applyLayout new grasky.LatticeLayout
  $('#sphere-layout-item').click -> graph.applyLayout new grasky.SphereLayout
  $('#auto-layout-item').click -> graph.applyLayout new grasky.ForceDirectedLayout
