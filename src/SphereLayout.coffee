grasky = window.grasky ?= {}

class grasky.SphereLayout
  REPULSION_CONSTANT = 0.02
  DRAG_CONSTANT = 0.05
  NUM_ITERATIONS = 2000
  BOUNDRY_DISTANCE = 20
  BOUNDRY_ATTRACTIVE_CONSTANT = 0.50

  getLayout: (nodeCount, edges) ->
    if nodeCount is 1
      new THREE.Vector3
    else
      particles = (new Particle for i in [0...nodeCount])
      for iteration in [0...NUM_ITERATIONS]
        for particle in particles
          particle.position.add particle.velocity
          particle.velocity.add @_dragForce particle
          particle.velocity.add @_boundryAttractiveForce particle
          for other in particles
            if particle != other
              particle.velocity.add @_repulsiveForce particle, other
      (particle.position for particle in particles)

  _dragForce: (particle) ->
    particle.velocity.clone().multiplyScalar -DRAG_CONSTANT

  _repulsiveForce: (particle, other) ->
    distance = particle.position.distanceTo other.position
    direction =
        new THREE.Vector3().subVectors particle.position, other.position
    direction.setLength REPULSION_CONSTANT / distance

  _boundryAttractiveForce: (particle) ->
    distance = Math.max BOUNDRY_DISTANCE - particle.position.length()
    particle.position.clone().setLength BOUNDRY_ATTRACTIVE_CONSTANT * distance
  
class Particle
  constructor: ->
    @position = new THREE.Vector3 Math.random(), Math.random(), Math.random()
    @velocity = new THREE.Vector3
