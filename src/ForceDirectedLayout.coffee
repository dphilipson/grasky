grasky = window.grasky ?= {}

class grasky.ForceDirectedLayout
  SPRING_CONSTANT = 0.001
  REPULSION_CONSTANT = 0.02
  DRAG_CONSTANT = 0.05
  NUM_ITERATIONS = 2000
  BOUNDRY_DISTANCE = 20

  getLayout: (nodeCount, edges) ->
    particles = (new Particle for i in [0...nodeCount])
    for iteration in [0...NUM_ITERATIONS]
      for particle in particles
        particle.position.add particle.velocity
        particle.velocity.add @_dragForce particle
        particle.velocity.add @_boundryRepulsiveForce particle
        for other in particles
          if particle != other
            particle.velocity.add @_repulsiveForce particle, other
      for edge in edges
        particle1 = particles[edge[0]]
        particle2 = particles[edge[1]]
        attractiveForce = @_edgeAttractiveForce particle1, particle2
        particle1.velocity.add attractiveForce
        particle2.velocity.sub attractiveForce
    particle.position for particle in particles

  _dragForce: (particle) ->
    particle.velocity.clone().multiplyScalar -DRAG_CONSTANT

  _repulsiveForce: (particle, other) ->
    distance = particle.position.distanceTo other.position
    direction =
        new THREE.Vector3().subVectors particle.position, other.position
    direction.setLength REPULSION_CONSTANT / distance

  _edgeAttractiveForce: (particle, other) ->
    distance = particle.position.distanceTo other.position
    direction =
        new THREE.Vector3().subVectors other.position, particle.position
    direction.setLength SPRING_CONSTANT * distance

  _boundryRepulsiveForce: (particle) ->
    distance = Math.max BOUNDRY_DISTANCE - particle.position.length(), 1
    particle.position.clone().setLength -REPULSION_CONSTANT / distance
    
  
class Particle
  constructor: ->
    @position = new THREE.Vector3 Math.random(), Math.random(), Math.random()
    @velocity = new THREE.Vector3
