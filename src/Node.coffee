grasky = window.grasky ?= {}

class grasky.Node
  COLOR = 0xe0e0e0
  SELECTION_COLOR = 0x170e6
  TEXT_COLOR = 0x000000

  constructor: (@id, @text, scene) ->
    @selected = false
    @_flightStart = new THREE.Vector3
    @_flightEnd = new THREE.Vector3
    @_flightProgress = 1
    @_edges = []
    @mesh = @_createSphere()
    @mesh.node = @
    scene.add @mesh
    @_initializeLabel()

  _createSphere: ->
    geometry = new THREE.SphereGeometry 0.5, 32, 32
    material = new THREE.MeshLambertMaterial color: COLOR
    new THREE.Mesh geometry, material

  _initializeLabel: ->
    @label = createText @text
    @label.width = @_getWidth(@label)
    @label.position.set -@label.width / 2, -1.2, 0
    @mesh.add @label

  createText = (text) ->
    geometry = new THREE.TextGeometry text,
      size: 0.5
      height: 0.05
    material = new THREE.MeshBasicMaterial color: TEXT_COLOR
    new THREE.Mesh geometry, material

  _getWidth: (mesh) ->
    mesh.geometry.computeBoundingBox()
    boundingBox = mesh.geometry.boundingBox
    boundingBox.max.x - boundingBox.min.x

  setSelected: (selected) ->
    @selected = selected
    color = if selected then SELECTION_COLOR else COLOR
    @mesh.material.color.setHex color

  setPosition: (x, y, z) ->
    @_flightStart.set x, y, z
    @_flightEnd.set x, y, z
    @_flightProgress = 1
    @mesh.position.set x, y, z

  setText: (text) ->
    unless text is @text
      @text = text
      @mesh.remove @label
      @_initializeLabel()

  setFlightTarget: (x, y, z) ->
    @_flightStart = @mesh.position.clone()
    @_flightEnd = new THREE.Vector3 x, y, z
    @_flightProgress = 0

  updateFlight: (progress) ->
    if @_flightProgress isnt 1
      @_flightProgress = Math.min 1, @_flightProgress + progress
      t = ease(@_flightProgress)
      @mesh.position.copy(@_flightStart).multiplyScalar(1 - t)
          .add @_flightEnd.clone().multiplyScalar(t)

  ease = (t) -> 3 * t * t - 2 * t * t * t
