Grasky
======

Grasky is a library for displaying three-dimensional graphs (the kind with
nodes and edges) in the browser. Try it yourself online at
<http://dphilipson.github.io/grasky>.

The graphs are drawn onto a canvas element using WebGL and support the
following operations:

* Adding or removing nodes or edges
* Setting the text of nodes or edges
* Selecting nodes with the mouse. Multiple nodes can be selected by holding
  shift or ctrl.
* Dragging nodes with the mouse, including multiple nodes at once if several
  are selected
* Applying one of several layouts to a group of nodes. Currently, these layous
  include a sphere, a lattice, and a "smart" layout.
* Changing the camera look direction by holding the mouse and moving it
* Flying the camera using the WASD keys. Together with the previous point, this
  allows "first-person shooter"-style camera controls.

Several of the layouts are implemented using force-directed layouts. This means
that the nodes are modeled as particles which exert forces on each other. For
example, the "smart" layout groups related nodes by applying an attractive
force between linked nodes and a repulsive force between all pairs of nodes.
