grasky = window.grasky ?= {}

class grasky.LinkedDict
  constructor: ->
    @_dict = {}
    @_list = new LinkedList
    @_size = 0

  put: (key, value) ->
    if @containsKey key
      node = @_dict[mangle key]
      oldValue = node.value
      node.value = value
      oldValue
    else
      node = @_list.createAndAddNode key, value
      @_dict[mangle key] = node
      @_size++
      undefined

  get: (key) -> @_dict[mangle key]?.value

  remove: (key) ->
    if @containsKey key
      node = @_dict[mangle key]
      @_list.removeNode node
      delete @_dict[mangle key]
      @_size--
      node.value
    else
      undefined

  containsKey: (key) -> @_dict.hasOwnProperty key

  size: -> @_size

  isEmpty: -> @_size is 0

  foreach: (f) -> @_list.foreach f

  keys: ->
    keys = []
    @_list.foreach (key, value) -> keys.push key
    keys

  values: ->
    values = []
    @_list.foreach (key, value) -> values.push value
    values

  # Prevent chaos if '__proto__' or 'hasOwnProperty' is given as a key.
  mangle = (key) -> '~' + key

  class LinkedList
    constructor: ->
      # @_start and @_end are dummy nodes
      @_start = {}
      @_end = {}
      @_start.next = @_end
      @_end.prev = @_start

    foreach: (f) ->
      curr = @_start.next
      while curr isnt @_end
        f curr.key, curr.value
        curr = curr.next
      return

    createAndAddNode: (key, value) ->
      node =
        key: key
        value: value
        prev: @_end.prev
        next: @_end
      @_end.prev.next = node
      @_end.prev = node
      node

    removeNode: (node) ->
      node.prev.next = node.next
      node.next.prev = node.prev
