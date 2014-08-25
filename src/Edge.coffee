grasky = window.grasky ?= {}

class grasky.Edge
  RADIUS = 0.0625
  COLOR = 0xc0c0c0
  TEXT_COLOR = 0x505050

  constructor: (node1, node2, @text, scene, id) ->
    @_scene = scene
    @nodes = [node1, node2]
    @mesh = createCylinder()
    scene.add @mesh
    @_initializeLabel()

  _initializeLabel: ->
    @label = createText @text
    @label.width = getWidth @label
    @_scene.add @label

  createCylinder = ->
    geometry = new THREE.CylinderGeometry RADIUS, RADIUS, 1
    material = new THREE.MeshLambertMaterial color: COLOR
    new THREE.Mesh geometry, material

  createText = (text) ->
    geometry = new THREE.TextGeometry text,
      size: 0.3
      height: 0.03
    material = new THREE.MeshBasicMaterial color: TEXT_COLOR
    new THREE.Mesh geometry, material

  getWidth = (mesh) ->
    mesh.geometry.computeBoundingBox()
    boundingBox = mesh.geometry.boundingBox
    boundingBox.max.x - boundingBox.min.x

  setText: (text) ->
    unless text is @text
      @text = text
      @_scene.remove @label
      @_initializeLabel()

  updatePosition: (camera) ->
    start = @nodes[0].mesh.position
    end = @nodes[1].mesh.position
    alignCylinderBetweenPoints @mesh, start, end
    midpoint = new THREE.Vector3()
        .addVectors start, end
        .multiplyScalar 0.5
    @label.rotation.set 0, camera.rotation.y, 0, 'YXZ'
    @label.position.copy midpoint
    @label.translateX -@label.width / 2
    @label.translateZ 0.6

  alignCylinderBetweenPoints = (cylinder, point1, point2) ->
    if point1.equals point2
      cylinder.scale.y = 0.01
    else
      direction = new THREE.Vector3().subVectors point2, point1
      arrow = new THREE.ArrowHelper direction.clone().normalize(), point1, 1
      cylinder.scale.y = direction.length()
      cylinder.rotation.copy arrow.rotation
      cylinder.position.addVectors point1, direction.multiplyScalar(0.5)

  getOtherNode: (node) ->
    if node is @nodes[0]
      @nodes[1]
    else if node is @nodes[1]
      @nodes[0]
    else
      console.error('Unexpected node in edge')

  dispose: ->
    @mesh.geometry.dispose
    @mesh.material.dispose
    @mesh.dispose
    @mesh = null
    @label.geometry.dispose
    @label.material.dispose
    @label.dispose
    @label = null
