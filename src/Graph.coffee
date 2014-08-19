grasky = window.grasky ?= {}

class grasky.Graph
  TWO_PI = 2 * Math.PI
  CAMERA_DISTANCE = 40
  SKYBOX_DISTANCE = 5000
  LOOP_PERIOD_MILLIS = 15
  NODE_FLIGHT_TIME_MILLIS = 1000
  # If the mouse is held longer than this, it is considered a drag.
  CLICK_TIMEOUT_MILLIS = 250
  FLY_SPEED = 0.25

  constructor: (canvas) ->
    @_canvas = canvas
    @_nodes = []
    @_edges = []
    @_selectionListeners = []
    @_draggedNodes = {}
    @_draggedNodeDistance = 0
    @_mouseX = 0
    @_mouseY = 0
    @_keysHeld = {}
    @_needsOrientationUpdate = false
    @_scene = new THREE.Scene
    @_camera = new THREE.PerspectiveCamera(
        45, canvas.clientWidth / canvas.clientHeight, 1.1, 10000)
    @_renderer = new THREE.WebGLRenderer canvas: canvas
    @_renderer.setSize canvas.clientWidth, canvas.clientHeight
    @_camera.position.z = CAMERA_DISTANCE
    @_initializeLights()
    @_initializeSkybox()
    @_initializeMouseListeners()
    @_initializeKeyboardListeners()

    renderLoop = =>
      @_fixLabelRotations()
      @_updateDraggedNodePositions()
      for edge in @_edges
        edge.updatePosition @_camera
      @_renderer.render @_scene, @_camera
      requestAnimationFrame renderLoop
    renderLoop()

    updateLoop = =>
      for node in @_nodes
        node.updateFlight LOOP_PERIOD_MILLIS / NODE_FLIGHT_TIME_MILLIS
      @_updateCameraMovement()
      setTimeout updateLoop, LOOP_PERIOD_MILLIS
    updateLoop()

  _initializeLights: ->
    directionalLight = new THREE.DirectionalLight 0xffffff, 0.8
    directionalLight.position.set 0.5, 1, 2
    @_scene.add directionalLight

    ambientLight = new THREE.AmbientLight 0x404040
    @_scene.add ambientLight

  _initializeSkybox: ->
    path = 'statics/textures/skybox/'
    filenames = ['px.jpg', 'nx.jpg', 'py.jpg', 'ny.jpg', 'pz.jpg', 'nz.jpg']
    urls = (path + filename for filename in filenames)
    textureCube = THREE.ImageUtils.loadTextureCube urls
    shader = THREE.ShaderLib['cube']
    shader.uniforms['tCube'].value = textureCube
    material = new THREE.ShaderMaterial
        fragmentShader: shader.fragmentShader
        vertexShader: shader.vertexShader
        uniforms: shader.uniforms
        side: THREE.BackSide
    sideLength = 2 * SKYBOX_DISTANCE
    skybox = new THREE.Mesh(
        new THREE.BoxGeometry(sideLength, sideLength, sideLength), material)
    @_scene.add skybox

  addNode: (id, text) ->
    unless @getNode id
      @_nodes.push new grasky.Node id, text, @_scene
    else
      console.error "Tried to add an existing node with id #{id}"

  removeNode: (id) ->
    node = @getNode id
    if node
      @_scene.remove node.mesh
      @_nodes = (n for n in @_nodes when n isnt node)
      for edge in _.filter @_edges, ((e) -> node in e.nodes)
        @_removeEdge edge
    else
      console.warn "Tried to remove nonexistant node with id #{id}"

  getNode: (id) -> _.find @_nodes, (node) -> node.id is id

  addEdge: (id1, id2, text, id) ->
    unless @getEdge id1, id2
      node1 = @getNode id1
      node2 = @getNode id2
      @_edges.push new grasky.Edge node1, node2, text, @_scene, id
    else
      console.error "Tried to add an existing edge with ids #{id1}, #{id2}"

  removeEdge: (id1, id2) ->
    edge = @getEdge id1, id2
    if edge
      @_removeEdge edge
    else
      console.warn "Tried to remove nonexistant edge with ids #{id1}, #{id2}"

  _removeEdge: (edge) ->
    @_scene.remove edge.mesh
    @_scene.remove edge.label
    @_edges = (e for e in @_edges when e isnt edge)

  getEdge: (id1, id2) ->
    _.find @_edges, (edge) ->
      ids = (n.id for n in edge.nodes)
      (_.contains ids, id1) and (_.contains ids, id2)

  addSelectionListener: (callback) ->
    @_selectionListeners.push callback

  removeSelectionListener: (callback) ->
    @_selectionListeners = _.reject @_selectionListeners, (c) -> c is callback

  setSelection: (id, selected) ->
    node = @getNode id
    if node
      @_setSelectionInternal node, selected
    else
      console.warn "Tried to set selection of nonexistant node with id #{id}"

  _setAsOnlySelectedNode: (node) ->
    for n in @_nodes
      n.setSelected false
    node.setSelected true
    @_notifySelectionListeners()

  _clearSelection: ->
    for n in @_nodes
      n.setSelected false
    @_notifySelectionListeners()

  _toggleSelection: (node) ->
    @_setSelectionInternal node, not node.selected

  _setSelectionInternal: (node, selected) ->
    node.setSelected selected
    @_notifySelectionListeners()

  _notifySelectionListeners: ->
    selectedIds = (n.id for n in @_getSelectedNodes())
    for listener in @_selectionListeners.slice()
      listener selectedIds
    return

  _getSelectedNodes: -> n for n in @_nodes when n.selected

  applyLayout: (layout) ->
    selectedNodes = @_getSelectedNodes()
    nodes = if selectedNodes.length > 0 then selectedNodes else @_nodes
    if nodes.length is 0
      return
    center = if selectedNodes.length is 0
      new THREE.Vector3
    else
      averageVectors(node.mesh.position for node in nodes)
    # To apply the layout, we need to represent the edges as pairs of indices.
    # Thus, first map the node ids to indices.
    nodeIds = (n.id for n in nodes)
    indices = {}
    for i in [0...nodeIds.length]
      indices[nodeIds[i]] = i
    edgesByIndex = []
    for edge in @_edges
      if edge.nodes[0].id of indices and edge.nodes[1].id of indices
        edgesByIndex.push [indices[edge.nodes[0].id], indices[edge.nodes[1].id]]
    locations = layout.getLayout nodeIds.length, edgesByIndex
    for i in [0...nodeIds.length]
      target = locations[i].add center
      nodes[i].setFlightTarget target.x, target.y, target.z
    return

  averageVectors = (vectors) ->
    sum = new THREE.Vector3
    for vector in vectors
      sum.add vector
    sum.multiplyScalar 1 / vectors.length

  _initializeMouseListeners: ->
    mouseLookActive = false
    mousedownTimer = null
    clickedNode = null
    wasSelectedAlready = false
    $(@_canvas).mousedown (event) =>
      mousedownTimer = new THREE.Clock()
      mousedownTimer.start()
      clickedNode = @_getNodeAtCanvasPoint event.offsetX, event.offsetY
      if clickedNode
        wasSelectedAlready = clickedNode.selected
        unless wasSelectedAlready
          if event.ctrlKey or event.shiftKey
            @_setSelectionInternal clickedNode, true
          else
            @_setAsOnlySelectedNode clickedNode
        @_draggedNodes = for selectedNode in @_getSelectedNodes()
          nodeCanvasPosition =
              @_getCanvasPointFromPosition selectedNode.mesh.position
          offset = new THREE.Vector2().subVectors nodeCanvasPosition,
              new THREE.Vector2 event.offsetX, event.offsetY
          distance = @_camera.position.distanceTo selectedNode.mesh.position
          new DraggedNode selectedNode, offset, distance
      else
        mouseLookActive = true
        @_mouseX = event.offsetX
        @_mouseY = event.offsetY
    reset = =>
      @_draggedNodes = []
      mouseLookActive = false
      clickedNode = null
      mousedownTimer = null
    $(@_canvas).mouseup (event) =>
      if mousedownTimer
        wasClick = 1000 * mousedownTimer.getElapsedTime() < CLICK_TIMEOUT_MILLIS
        modifierHeld = event.ctrlKey or event.shiftKey
        if wasClick
          if clickedNode
            if modifierHeld
              if wasSelectedAlready
                @_setSelectionInternal clickedNode, false
            else
              @_setAsOnlySelectedNode clickedNode
          else unless modifierHeld
            @_clearSelection()
      reset()
    $(@_canvas).mouseout => reset()
    $(@_canvas).mousemove (event) =>
      x = event.offsetX
      y = event.offsetY
      xDelta = x - @_mouseX
      yDelta = y - @_mouseY
      @_mouseX = x
      @_mouseY = y
      if mouseLookActive
        @_updateRotation(xDelta, yDelta)

  _getNodeAtCanvasPoint: (x, y) ->
    vector = @_getVectorFromCanvasPoint x, y
    raycaster = new THREE.Raycaster @_camera.position, vector
    intersects = raycaster.intersectObjects (n.mesh for n in @_nodes)
    if intersects.length > 0
      intersects[0].object.node

  _getVectorFromCanvasPoint: (x, y) ->
    # Normally the matrix is updated at the next render step, but we need it to
    # be up to date here for the projector to work.
    @_camera.updateMatrixWorld()
    vector = new THREE.Vector3 2 * x / @_canvas.clientWidth - 1,
        -2 * y / @_canvas.clientHeight + 1
        0.5
    new THREE.Projector().unprojectVector vector, @_camera
        .sub @_camera.position
        .normalize()

  _getCanvasPointFromPosition: (position) ->
    vector = new THREE.Vector3().copy position
    new THREE.Projector().projectVector vector, @_camera
    x = (vector.x + 1) / 2 * @_canvas.clientWidth
    y = (1 - vector.y) / 2 * @_canvas.clientHeight
    new THREE.Vector2 x, y

  _updateRotation: (deltaX, deltaY) ->
    yaw = @_camera.rotation.y
    pitch = @_camera.rotation.x
    newYaw = yaw - deltaX * TWO_PI / 1500
    newPitch = pitch - deltaY * TWO_PI / 1500
    newPitch = Math.min(Math.PI / 2, Math.max(-Math.PI / 2, newPitch))
    @_camera.rotation.set newPitch, newYaw, @_camera.rotation.z, 'YXZ'
    @_needsOrientationUpdate = true

  _fixLabelRotations: ->
    if @_needsOrientationUpdate
      for node in @_nodes
        label = node.label
        label.translateX label.width / 2
        label.rotation.set 0, @_camera.rotation.y, 0, 'YXZ'
        label.translateX -label.width / 2
      @_needsOrientationUpdate = false 

  _updateDraggedNodePositions: ->
    for draggedNode in @_draggedNodes
      vector = @_getVectorFromCanvasPoint @_mouseX + draggedNode.offset.x,
          @_mouseY + draggedNode.offset.y
      vector.setLength(draggedNode.distance).add @_camera.position
      draggedNode.node.setPosition vector.x, vector.y, vector.z

  _initializeKeyboardListeners: ->
    $(document).keydown (event) =>
      @_keysHeld[event.which] = true
      if event.which is 8 or event.which is 46
        # Backspace and delete
        for node in @_getSelectedNodes()
          @removeNode node.id
        event.preventDefault()
    $(document).keyup (event) => delete @_keysHeld[event.which]

  _updateCameraMovement: ->
    wPressed = 'W'.charCodeAt() of @_keysHeld
    aPressed = 'A'.charCodeAt() of @_keysHeld
    sPressed = 'S'.charCodeAt() of @_keysHeld
    dPressed = 'D'.charCodeAt() of @_keysHeld
    forward = (if wPressed then 1 else 0) - (if sPressed then 1 else 0)
    right = (if dPressed then 1 else 0) - (if aPressed then 1 else 0)
    @_camera.translateZ -FLY_SPEED * forward
    @_camera.translateX FLY_SPEED * right

  fixViewBounds: ->
    width = @_canvas.clientWidth
    height = @_canvas.clientHeight
    @_camera.aspect = width / height
    @_camera.updateProjectionMatrix()
    @_renderer.setSize width, height


  class DraggedNode
    constructor: (@node, @offset, @distance) ->
