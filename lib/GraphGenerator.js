// Generated by CoffeeScript 1.7.1
(function() {
  var grasky,
    __slice = [].slice;

  grasky = window.grasky != null ? window.grasky : window.grasky = {};

  grasky.GraphGenerator = (function() {
    var EDGES, NAMES, addToGraph;

    function GraphGenerator() {}

    NAMES = ['Bella', 'Edward', 'Jacob', 'Carlisle', 'Esme', 'Alice', 'Emmett', 'Rosalie', 'Jasper', 'Renesmee', 'James', 'Victoria', 'Laurent', 'Riley', 'Bree', 'Aro', 'Caius', 'Marcus', 'Jane', 'Alec', 'Demetri', 'Felix', 'Heidi', 'Leah', 'Seth'];

    EDGES = ['Siblings', 'Friends', 'Enemies', 'Co-workers', 'Allies', 'Teammates', 'Associates', 'Roommates', 'Flatmates', 'Partners', 'Co-owners', 'Lovers', 'In bloodpact'];

    GraphGenerator.prototype.gilbertGraph = function(graph, count, p) {
      var edges, i, j, names, _i, _j, _ref;
      names = (function() {
        var _i, _results;
        _results = [];
        for (i = _i = 0; 0 <= count ? _i < count : _i > count; i = 0 <= count ? ++_i : --_i) {
          _results.push(NAMES[i]);
        }
        return _results;
      })();
      edges = [];
      for (i = _i = 0; 0 <= count ? _i < count : _i > count; i = 0 <= count ? ++_i : --_i) {
        for (j = _j = _ref = i + 1; _ref <= count ? _j < count : _j > count; j = _ref <= count ? ++_j : --_j) {
          if (Math.random() < p) {
            edges.push({
              nodes: [i, j],
              label: EDGES[edges.length % EDGES.length]
            });
          }
        }
      }
      return addToGraph(graph, names, edges);
    };

    addToGraph = function(graph, names, edges) {
      var edge, i, name, _i, _j, _len, _len1, _results;
      for (i = _i = 0, _len = names.length; _i < _len; i = ++_i) {
        name = names[i];
        graph.addNode(i, name);
      }
      _results = [];
      for (i = _j = 0, _len1 = edges.length; _j < _len1; i = ++_j) {
        edge = edges[i];
        _results.push(graph.addEdge.apply(graph, __slice.call(edge.nodes).concat([edge.label], [i])));
      }
      return _results;
    };

    return GraphGenerator;

  })();

}).call(this);