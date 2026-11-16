(function (root) {
  "use strict";

  function indexById(items) {
    return new Map(items.map(item => [item.id, item]));
  }

  function collapsedOwner(groupId, groups, collapsed) {
    let owner = null;
    while (groupId && groupId !== "root") {
      if (collapsed.has(groupId)) owner = groupId;
      const group = groups.get(groupId);
      if (!group) throw new Error("Unknown subroutine: " + groupId);
      groupId = group.parent;
    }
    return owner;
  }

  function productStatus(node) {
    if (node.exported) return "exported";
    if (node.external) return "input";
    if (node.temporary) return "temporary";
    if (node.retired) return "retired";
    if (node.final) return "output";
    return "intermediate";
  }

  function matchesScope(node, scope) {
    if (!scope || scope === "all") return true;
    if (scope === "output") return node.final && !node.external;
    if (scope === "runtime") return node.runtime_resolved;
    return productStatus(node) === scope;
  }

  function traceIds(graph, id, direction) {
    if (!["upstream", "downstream"].includes(direction)) throw new Error("Unknown lineage direction: " + direction);
    if (!graph.nodes.some(node => node.id === id)) throw new Error("The selected product is not in this view");
    const adjacent = new Map(graph.nodes.map(node => [node.id, []]));
    for (const edge of graph.edges) {
      if (edge.kind !== "data") continue;
      if (direction !== "downstream") adjacent.get(edge.target).push(edge.source);
      if (direction !== "upstream") adjacent.get(edge.source).push(edge.target);
    }
    const found = new Set([id]), queue = [id];
    for (let cursor = 0; cursor < queue.length; cursor++) {
      for (const next of adjacent.get(queue[cursor])) {
        if (!found.has(next)) {found.add(next); queue.push(next);}
      }
    }
    return found;
  }

  function focusGraph(graph, id, direction) {
    // Keep ancestors and descendants, not unrelated sibling branches reached
    // by walking backwards and then forwards through a shared input.
    const included = direction === "both" ?
      new Set([...traceIds(graph, id, "upstream"), ...traceIds(graph, id, "downstream")]) :
      traceIds(graph, id, direction);
    return Object.assign({}, graph, {
      nodes: graph.nodes.filter(node => included.has(node.id)),
      edges: graph.edges.filter(edge => included.has(edge.source) && included.has(edge.target))
    });
  }

  function projectGraph(model, options) {
    const groups = indexById(model.groups);
    const originals = indexById(model.nodes);
    const grouped = options.mode === "pipeline" && Boolean(options.groupContext);
    const collapsed = new Set(grouped ? options.collapsed || [] : []);
    const activeActions = new Set(model.nodes.filter(node =>
      node.kind === "action" && (options.showSkipped || node.active)
    ).map(node => node.id));
    const adjacent = new Map(model.nodes.map(node => [node.id, []]));
    for (const edge of model.edges) {
      if (!originals.has(edge.source) || !originals.has(edge.target)) {
        throw new Error("Graph connection refers to an unknown node");
      }
      if (edge.kind === "data") {
        adjacent.get(edge.source).push(edge.target);
        adjacent.get(edge.target).push(edge.source);
      }
    }
    const included = new Set(model.nodes.filter(node => node.kind === "action" ?
      activeActions.has(node.id) : options.showSkipped ||
      adjacent.get(node.id).some(id => activeActions.has(id)) ||
      (node.head && node.final && node.active)
    ).map(node => node.id));
    const owners = new Map();
    for (const node of model.nodes) {
      const preResume = !options.showSkipped && !node.active;
      owners.set(node.id, !grouped || preResume ? null : collapsedOwner(node.group, groups, collapsed));
    }
    const folded = new Map();
    const representatives = {};

    function addGroup(id) {
      const key = "group:" + id;
      if (!folded.has(key)) {
        const group = groups.get(id);
        const count = group.actions.filter(action => activeActions.has(action)).length;
        folded.set(key, {
          id: key, kind: "group", label: group.label, name: group.label,
          group: id, display_group: id, number: group.number,
          order: group.start, count: count, active: true
        });
      }
      return key;
    }

    for (const node of model.nodes) {
      if (!included.has(node.id)) continue;
      const owner = owners.get(node.id);
      const boundary = node.kind === "product" && owner &&
        (node.final || adjacent.get(node.id).some(id =>
          included.has(id) && owners.get(id) !== owner
        ));
      if (owner && !boundary) {
        representatives[node.id] = addGroup(owner);
      } else {
        representatives[node.id] = node.id;
        folded.set(node.id, Object.assign({}, node, {
          display_group: !grouped || (!options.showSkipped && !node.active) ? "root" : node.group,
          pre_resume: !options.showSkipped && !node.active
        }));
      }
    }
    if (grouped) {
      for (const group of model.groups) {
        if (group.variables.some(variable => options.showSkipped || variable.active)) {
          const owner = collapsedOwner(group.id, groups, collapsed);
          if (owner) addGroup(owner);
        }
      }
    }
    const foldedEdges = [];
    for (const edge of model.edges) {
      if (edge.kind === "order" && (!options.showOrder || options.mode === "products")) continue;
      if (!included.has(edge.source) || !included.has(edge.target)) continue;
      const source = representatives[edge.source], target = representatives[edge.target];
      if (source === target) continue;
      // A boundary output can also be consumed internally. Do not turn that
      // internal reuse into a spurious output-to-collapsed-routine cycle.
      if (edge.kind === "data" && target.startsWith("group:") &&
          owners.get(edge.source) === target.slice(6) &&
          originals.get(edge.source).kind === "product") continue;
      const via = [], operations = [];
      for (const id of [edge.source, edge.target]) {
        const original = originals.get(id);
        if (original.kind === "action" && representatives[id] !== id) {
          via.push(original.label);
          operations.push(id);
        }
      }
      foldedEdges.push({source, target, kind: edge.kind, via, operations});
    }
    const hidden = new Set();
    for (const node of folded.values()) {
      if ((options.mode === "products" && node.kind === "action") ||
          (node.kind === "product" && !matchesScope(node, options.scope)) ||
          (node.head && !options.showHead && !node.external && !node.final)) {
        hidden.add(node.id);
      }
    }
    const outgoing = new Map(Array.from(folded.keys(), id => [id, []]));
    for (const edge of foldedEdges) outgoing.get(edge.source).push(edge);
    const projected = new Map();
    for (const node of folded.values()) {
      if (hidden.has(node.id)) continue;
      for (const kind of ["data", "order"]) {
        const queue = (outgoing.get(node.id) || []).filter(edge => edge.kind === kind).map(edge => ({
          target: edge.target, via: edge.via.slice(), operations: edge.operations.slice()
        }));
        const visited = new Map();
        for (let cursor = 0; cursor < queue.length; cursor++) {
          const path = queue[cursor], target = folded.get(path.target);
          if (target.id === node.id) continue;
          if (!hidden.has(target.id)) {
            const key = node.id + "|" + target.id + "|" + kind;
            if (!projected.has(key)) projected.set(key, {
              id: "v" + projected.size, source: node.id, target: target.id,
              kind: kind, via: [], operations: []
            });
            const edge = projected.get(key);
            edge.via = Array.from(new Set(edge.via.concat(path.via)));
            edge.operations = Array.from(new Set(edge.operations.concat(path.operations)))
              .sort((a, b) => originals.get(a).order - originals.get(b).order);
          } else {
            const operations = new Set(path.operations);
            if (target.kind === "action") operations.add(target.id);
            const previous = visited.get(target.id);
            if (previous && Array.from(operations).every(id => previous.has(id))) continue;
            for (const id of previous || []) operations.add(id);
            visited.set(target.id, operations);
            const via = target.kind === "action" ? path.via.concat(target.label) : path.via;
            for (const next of outgoing.get(target.id) || []) {
              if (next.kind === kind) queue.push({
                target: next.target, via: via.concat(next.via),
                operations: Array.from(operations).concat(next.operations)
              });
            }
          }
        }
      }
    }
    return {
      nodes: Array.from(folded.values()).filter(node => !hidden.has(node.id)),
      edges: Array.from(projected.values()), representatives, grouped
    };
  }

  function layoutGraph(graph, model) {
    const nodes = indexById(graph.nodes);
    const incoming = new Map(graph.nodes.map(node => [node.id, 0]));
    const outgoing = new Map(graph.nodes.map(node => [node.id, []]));
    const rank = new Map(graph.nodes.map(node => [node.id, 0]));
    for (const edge of graph.edges) {
      incoming.set(edge.target, incoming.get(edge.target) + 1);
      outgoing.get(edge.source).push(edge.target);
    }
    const queue = graph.nodes.filter(node => incoming.get(node.id) === 0)
      .sort((a, b) => a.order - b.order).map(node => node.id);
    for (let cursor = 0; cursor < queue.length; cursor++) {
      const source = queue[cursor];
      for (const target of outgoing.get(source)) {
        rank.set(target, Math.max(rank.get(target), rank.get(source) + 1));
        incoming.set(target, incoming.get(target) - 1);
        if (incoming.get(target) === 0) queue.push(target);
      }
    }
    if (queue.length !== graph.nodes.length) {
      throw new Error("The visible graph contains a cycle; inspect the construction metadata");
    }
    const maxRank = graph.nodes.length ? Math.max(...Array.from(rank.values())) : 0;
    if (!graph.grouped) {
      const columns = new Map(), parents = new Map(graph.nodes.map(node => [node.id, new Set()]));
      for (const node of graph.nodes) {
        const column = rank.get(node.id);
        if (!columns.has(column)) columns.set(column, []);
        columns.get(column).push(node);
      }
      for (const edge of graph.edges) parents.get(edge.target).add(edge.source);
      const positions = new Map(), bands = [];
      const rows = Math.max(1, ...Array.from(columns.values(), entries => entries.length));
      const height = Math.max(360, rows * 136 + 130);
      for (const [column, entries] of Array.from(columns).sort((a, b) => a[0] - b[0])) {
        function centre(node) {
          const predecessors = Array.from(parents.get(node.id)).map(id => positions.get(id)).filter(Boolean);
          return predecessors.length ? predecessors.reduce((sum, item) => sum + item.y, 0) / predecessors.length : node.order;
        }
        entries.sort((a, b) => centre(a) - centre(b) || a.order - b.order || a.id.localeCompare(b.id));
        const offset = (height - 76 - entries.length * 136) / 2;
        entries.forEach((node, row) => positions.set(node.id, {
          x: 38 + column * 306, y: 76 + offset + row * 136, width: 240, height: 108
        }));
        bands.push({
          rank: column, x: 22 + column * 306, width: 272,
          label: entries.every(node => node.external) ? "Source data" : "Dependency layer " + (column + 1)
        });
      }
      return {positions, columns: bands, lanes: [], width: 322 + maxRank * 306, height};
    }
    const lanes = [];
    const positions = new Map();
    let top = 32;
    for (const group of model.groups) {
      const members = graph.nodes.filter(node => node.display_group === group.id);
      if (!members.length) continue;
      const columns = new Map();
      for (const node of members) {
        const column = rank.get(node.id);
        if (!columns.has(column)) columns.set(column, []);
        columns.get(column).push(node);
      }
      const maximum = Math.max(...Array.from(columns.values(), column => column.length));
      const height = maximum * 116 + 48;
      lanes.push({group: group.id, y: top, height: height});
      for (const [column, entries] of columns) {
        entries.sort((a, b) => a.order - b.order || a.id.localeCompare(b.id));
        entries.forEach((node, row) => positions.set(node.id, {
          x: 38 + column * 306, y: top + 42 + row * 116, width: 240, height: 86
        }));
      }
      top += height + 22;
    }
    return {positions, lanes, columns: [], width: 322 + maxRank * 306, height: Math.max(top, 220)};
  }

  const api = {projectGraph, layoutGraph, focusGraph, traceIds, productStatus};
  root.PipelineGraph = api;
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  if (typeof document === "undefined") return;

  const ns = "http://www.w3.org/2000/svg";
  const byId = id => document.getElementById(id);
  function svgElement(name, attributes, text) {
    const element = document.createElementNS(ns, name);
    for (const [key, value] of Object.entries(attributes || {})) element.setAttribute(key, value);
    if (text !== undefined) element.textContent = text;
    return element;
  }
  function element(name, text, className) {
    const node = document.createElement(name);
    if (text !== undefined) node.textContent = text;
    if (className) node.className = className;
    return node;
  }
  function wrap(text, limit) {
    const lines = [];
    for (let index = 0; index < text.length; index += limit) lines.push(text.slice(index, index + limit));
    return lines.length ? lines : [""];
  }

  try {
    const model = JSON.parse(byId("graph-data").textContent);
    const groups = indexById(model.groups), originals = indexById(model.nodes);
    const consumerIndex = new Map(model.nodes.map(node => [node.id, []]));
    for (const edge of model.edges) {
      const target = originals.get(edge.target);
      if (edge.kind === "data" && target.kind === "action" && target.operation !== "delete") {
        consumerIndex.get(edge.source).push(target);
      }
    }
    const collapsed = new Set(model.groups.filter(group => group.parent !== null).map(group => group.id));
    let graph, catalogueGraph, layout, selected = null, camera = null, drag = null;
    let view = "lineage", focus = null;
    const statusLabels = {
      input: "Inherited input", output: "Available output", temporary: "Temporary",
      retired: "Superseded / renamed", exported: "Exported", intermediate: "Intermediate"
    };
    const svg = byId("graph");
    byId("pipeline-title").textContent = model.pipeline;
    byId("resume-control").hidden = !model.resumed;
    if (model.summary.runtime_names) {
      byId("notice").hidden = false;
      byId("notice").textContent = "Some product names are runtime-resolved. Symbolic declarations are kept distinct instead of merging validation placeholders.";
    }
    function options() {
      return {
        collapsed: Array.from(collapsed), mode: byId("view-mode").value,
        showHead: byId("show-head").checked, showOrder: byId("show-order").checked,
        showSkipped: byId("show-skipped").checked,
        groupContext: byId("group-context").checked, scope: byId("product-scope").value
      };
    }
    function scope(groupId) {
      const labels = [];
      while (groupId && groupId !== "root") {
        const group = groups.get(groupId);
        labels.unshift(group.label + " [" + group.number + "]");
        groupId = group.parent;
      }
      return labels.length ? labels.join(" / ") : model.pipeline;
    }
    function updateCamera() {
      svg.setAttribute("viewBox", [camera.x, camera.y, camera.width, camera.height].join(" "));
      const window = byId("mini-window");
      if (window) for (const key of ["x", "y", "width", "height"]) window.setAttribute(key, camera[key]);
    }
    function fit() {
      const ratio = Math.max(svg.clientWidth, 1) / Math.max(svg.clientHeight, 1);
      const width = Math.max(layout.width, layout.height * ratio), height = width / ratio;
      camera = {x: (layout.width - width) / 2, y: (layout.height - height) / 2, width, height};
      updateCamera();
    }
    function readable() {
      const width = Math.max(svg.clientWidth, 1), height = Math.max(svg.clientHeight, 1);
      const scale = Math.max(0.82, Math.min(1, width / layout.width, height / layout.height));
      camera = {
        x: 0, y: 0, width: width / scale, height: height / scale
      };
      updateCamera();
    }
    function zoom(factor, x, y) {
      x = x === undefined ? camera.x + camera.width / 2 : x;
      y = y === undefined ? camera.y + camera.height / 2 : y;
      camera = {
        x: x - (x - camera.x) * factor, y: y - (y - camera.y) * factor,
        width: camera.width * factor, height: camera.height * factor
      };
      updateCamera();
    }
    function expand(groupId) {
      while (groupId && groupId !== "root") {
        collapsed.delete(groupId);
        groupId = groups.get(groupId).parent;
      }
    }
    function toggle(groupId) {
      if (collapsed.has(groupId)) expand(groupId); else collapsed.add(groupId);
      redraw(true);
    }
    function badge(node) {
      const status = productStatus(node);
      return element("span", statusLabels[status], "badge status-" + status);
    }
    function nodeLabel(node) {
      return node.kind === "product" ? node.label + " · v" + node.version : node.label;
    }
    function setView(next) {
      view = next;
      byId("view-mode").value = view === "processes" ? "pipeline" : "products";
      byId("canvas").hidden = view === "catalogue";
      byId("catalogue").hidden = view !== "catalogue";
      byId("graph-tools").hidden = view === "catalogue";
      byId("graph-hint").hidden = view === "catalogue";
      byId("download-svg").disabled = view === "catalogue";
      byId("process-controls").hidden = view !== "processes";
      svg.setAttribute("aria-label", view === "processes" ? "Pipeline processing map" : "Pipeline data lineage");
      for (const tab of document.querySelectorAll("[data-view]")) {
        tab.setAttribute("aria-selected", String(tab.dataset.view === view));
        tab.tabIndex = tab.dataset.view === view ? 0 : -1;
      }
      byId("visualisation").setAttribute("aria-labelledby", "tab-" + view);
      redraw(true);
    }
    function reveal(node, direction) {
      byId("product-scope").value = "all";
      byId("group-context").checked = false;
      byId("search").value = "";
      if (!node.active) byId("show-skipped").checked = true;
      if (node.head) byId("show-head").checked = true;
      focus = direction ? {id: node.id, direction} : null;
      setView(node.kind === "action" ? "processes" : "lineage");
      selectNode(originals.get(node.id) || node);
      const position = layout.positions.get(node.id);
      if (position) {
        camera.x = position.x + position.width / 2 - camera.width / 2;
        camera.y = position.y + position.height / 2 - camera.height / 2;
        updateCamera();
      }
    }
    function nodeLink(node, navigate=false) {
      const button = element("button", nodeLabel(node), "product-link");
      button.title = "Identity " + node.id;
      button.addEventListener("click", () => navigate ? reveal(node) : selectNode(node));
      return button;
    }
    function consumers(node) {
      return consumerIndex.get(node.id);
    }
    function showDetails(node) {
      const panel = byId("details");
      panel.replaceChildren(element("h3", node.label));
      const list = element("dl");
      function field(label, value) {
        list.append(element("dt", label), element("dd", String(value)));
      }
      if (node.kind === "group") {
        const group = groups.get(node.group);
        field("Subroutine context", scope(node.group));
        field("Invocation", group.number);
        field("Declared operations", group.actions.length);
        panel.append(list);
        const button = element("button", "Expand this subroutine");
        button.addEventListener("click", () => {expand(node.group); redraw(true);});
        panel.append(button);
        if (group.variables.length) {
          panel.append(element("h4", "Variable assignments"));
          const variables = element("ul");
          for (const variable of group.variables) variables.append(element("li", variable.name + " = " + variable.value));
          panel.append(variables);
        }
        return;
      }
      field("Identity", node.id);
      if (node.kind === "product") {
        panel.append(badge(node));
        field("Product version", node.version);
        if (node.head) field("Product type", "Working DATAHEAD alias, not a named block product");
        field("Origin", node.created_by ? originals.get(node.created_by).label : "Inherited input");
        field("Lifetime", node.retired ? node.retired_reason : "Available at the end of construction");
        if (node.temporary) field("Temporary", "Deleted after use; later products with the same name have different identities");
        if (node.pre_resume) field("Resume context", "Produced before the resumed portion");
        if (node.runtime_resolved) field("Name", "Symbolic; the exact name is resolved at runtime");
      } else {
        field("Construction order", node.order);
        field("Operation", node.operation);
        if (!node.active) field("Resume context", "Not executed by the resumed pipeline");
        if (node.declared_inputs) field("Declared inputs", node.declared_inputs);
        if (node.declared_outputs) field("Declared outputs", node.declared_outputs);
      }
      panel.append(list);
      if (node.kind === "product") {
        const actions = element("div", undefined, "trace-actions");
        for (const [label, direction] of [["Trace inputs", "upstream"], ["Trace descendants", "downstream"], ["Full lineage", "both"], ["Open in flow", null]]) {
          const button = element("button", label, direction === "both" ? "primary" : "");
          button.addEventListener("click", () => reveal(node, direction));
          actions.append(button);
        }
        panel.append(actions);
        if (node.created_by) {
          panel.append(element("h4", "Produced by"), nodeLink(originals.get(node.created_by), true));
        }
        const readers = consumers(node);
        if (readers.length) {
          panel.append(element("h4", "Used by"));
          const entries = element("ul");
          for (const reader of readers) {
            const item = element("li");
            const link = nodeLink(reader, true);
            link.append(element("small", " · operation " + reader.order));
            item.append(link); entries.append(item);
          }
          panel.append(entries);
        }
      }
      const connectionsGraph = node.kind === "product" ? catalogueGraph : model;
      const connectedNodes = node.kind === "product" ? indexById(catalogueGraph.nodes) : originals;
      for (const [title, target] of [["Input products", true], ["Generated products", false]]) {
        const connections = connectionsGraph.edges.filter(edge => edge.kind === "data" &&
          (target ? edge.target : edge.source) === node.id);
        if (!connections.length) continue;
        panel.append(element("h4", title));
        const entries = element("ul");
        for (const edge of connections) {
          const item = element("li");
          item.append(nodeLink(connectedNodes.get(target ? edge.source : edge.target)));
          entries.append(item);
        }
        panel.append(entries);
      }
      const context = element("details");
      context.append(element("summary", "Source / subroutine context"), element("p", scope(node.group)));
      if (node.number) context.append(element("p", "Source step " + node.number));
      panel.append(context);
    }
    function selectNode(node) {
      selected = {kind: "node", id: node.id};
      showDetails(node);
      for (const entry of svg.querySelectorAll("[data-node]")) {
        entry.classList.toggle("selected", entry.dataset.node === node.id);
      }
      for (const entry of svg.querySelectorAll(".edge")) entry.classList.remove("selected");
      updateSearch();
    }
    function selectEdge(edge) {
      selected = {kind: "edge", id: edge.id};
      const panel = byId("details");
      panel.replaceChildren(element("h3", edge.kind === "order" ? "Execution order" : "Data dependency"));
      const visible = indexById(graph.nodes);
      panel.append(element("p", nodeLabel(visible.get(edge.source)) + " → " + nodeLabel(visible.get(edge.target))));
      if (edge.operations.length) {
        panel.append(element("h4", "Data is generated through"));
        const list = element("ul");
        for (const id of edge.operations) {
          const item = element("li"), operation = originals.get(id);
          const link = nodeLink(operation, true);
          link.append(element("small", " · operation " + operation.order));
          item.append(link); list.append(item);
        }
        panel.append(list);
      } else if (edge.via.length) {
        panel.append(element("h4", "Through these operations"));
        const list = element("ul");
        for (const label of edge.via) list.append(element("li", label));
        panel.append(list);
      }
      for (const entry of svg.querySelectorAll("[data-node]")) entry.classList.remove("selected");
      for (const entry of svg.querySelectorAll(".edge")) {
        entry.classList.toggle("selected", entry.dataset.edge === edge.id);
      }
      updateSearch();
    }
    function updateSearch() {
      const text = byId("search").value.trim().toLowerCase();
      const matches = new Set();
      const candidates = view === "processes" ?
        model.nodes.filter(node => node.kind !== "action" || byId("show-skipped").checked || node.active) :
        catalogueGraph.nodes;
      const results = byId("search-results");
      results.replaceChildren();
      let total = 0;
      if (text) {
        for (const node of candidates) {
          if (searchText(node).includes(text)) {
            total++;
            const representative = graph.representatives[node.id];
            if (representative) matches.add(representative);
            if (total <= 8) {
              const button = nodeLink(node, true);
              button.append(element("small", node.kind === "product" ? statusLabels[productStatus(node)] : "Operation " + node.order));
              results.append(button);
            }
          }
        }
        for (const node of graph.nodes) {
          if (node.kind === "group" && scope(node.group).toLowerCase().includes(text)) matches.add(node.id);
        }
      }
      let upstream = new Set(), downstream = new Set();
      if (selected && selected.kind === "node" && graph.nodes.some(node => node.id === selected.id)) {
        upstream = traceIds(graph, selected.id, "upstream");
        downstream = traceIds(graph, selected.id, "downstream");
      }
      for (const entry of svg.querySelectorAll("[data-node]")) {
        const id = entry.dataset.node;
        entry.classList.toggle("selected", Boolean(selected) && selected.kind === "node" && selected.id === id);
        entry.classList.toggle("upstream", !text && upstream.has(id) && selected.id !== id);
        entry.classList.toggle("downstream", !text && downstream.has(id) && selected.id !== id);
        entry.classList.toggle("match", Boolean(text) && matches.has(entry.dataset.node));
        entry.classList.toggle("dim", text ? !matches.has(id) :
          upstream.size > 0 && !upstream.has(id) && !downstream.has(id));
      }
      const visibleEdges = indexById(graph.edges);
      for (const entry of svg.querySelectorAll(".edge")) {
        const edge = visibleEdges.get(entry.dataset.edge);
        entry.classList.toggle("upstream", !text && upstream.has(edge.source) && upstream.has(edge.target));
        entry.classList.toggle("downstream", !text && downstream.has(edge.source) && downstream.has(edge.target));
        entry.classList.toggle("dim", Boolean(text) && !matches.has(edge.source) && !matches.has(edge.target));
      }
      byId("search-count").textContent = text ? total + " matches" + (total > 8 ? " · first 8 shown" : "") : "";
      if (view === "catalogue") renderCatalogue();
    }
    function searchText(node) {
      const producer = node.created_by ? originals.get(node.created_by).label : "";
      return (node.label + " " + producer).toLowerCase();
    }
    function renderCatalogue() {
      const text = byId("search").value.trim().toLowerCase();
      const products = graph.nodes.filter(node => node.kind === "product" && (!text || searchText(node).includes(text)));
      const sort = byId("sort-products").value;
      products.sort((a, b) => {
        if (sort === "name") return a.name.localeCompare(b.name) || a.version - b.version;
        if (sort === "status") return productStatus(a).localeCompare(productStatus(b)) || a.order - b.order;
        return a.order - b.order || a.id.localeCompare(b.id);
      });
      const rows = byId("product-rows");
      rows.replaceChildren();
      for (const node of products) {
        const row = element("tr");
        row.dataset.product = node.id;
        if (selected && selected.kind === "node" && selected.id === node.id) row.className = "selected";
        const name = element("td");
        name.append(nodeLink(node), element("small", node.id +
          (node.head ? " · working-head alias" : "") + (node.pre_resume ? " · pre-resume input" : "")));
        const state = element("td"); state.append(badge(node));
        row.append(name, element("td", "v" + node.version), state,
          element("td", node.created_by ? originals.get(node.created_by).label : "Inherited input"),
          element("td", consumers(node).length));
        rows.append(row);
      }
      byId("catalogue-empty").hidden = products.length !== 0;
      const heads = products.filter(node => node.head).length;
      byId("summary").textContent = (products.length - heads) + " named versions" +
        (heads ? " · " + heads + " working-head aliases" : "") + " · select a row to inspect";
    }
    function renderMinimap() {
      const mini = byId("minimap");
      mini.setAttribute("viewBox", "0 0 " + layout.width + " " + layout.height);
      mini.replaceChildren();
      for (const edge of graph.edges) {
        if (edge.kind !== "data") continue;
        const source = layout.positions.get(edge.source), target = layout.positions.get(edge.target);
        mini.append(svgElement("line", {x1: source.x + source.width, y1: source.y + source.height / 2,
          x2: target.x, y2: target.y + target.height / 2, stroke: "#c2cede", "stroke-width": 3}));
      }
      const colours = {input: "#3266df", output: "#0e7565", temporary: "#966018", retired: "#596b85", exported: "#7958bc", intermediate: "#596b85"};
      for (const node of graph.nodes) {
        const position = layout.positions.get(node.id);
        mini.append(svgElement("rect", {
          x: position.x, y: position.y, width: position.width, height: position.height, rx: 10,
          fill: node.kind === "product" ? colours[productStatus(node)] : "#6878b3"
        }));
      }
      mini.append(svgElement("rect", {id: "mini-window", class: "mini-window", "stroke-width": layout.width / 140}));
      byId("mini-panel").hidden = graph.nodes.length === 0;
    }
    function redraw(resetCamera) {
      try {
        const settings = options();
        catalogueGraph = projectGraph(model, Object.assign({}, settings, {mode: "products", scope: "all", groupContext: false}));
        graph = settings.mode === "products" && settings.scope === "all" ?
          catalogueGraph : projectGraph(model, settings);
        if (focus) graph = focusGraph(graph, focus.id, focus.direction);
        layout = layoutGraph(graph, model);
        byId("error").hidden = true;
        byId("empty").hidden = graph.nodes.length !== 0;
        byId("show-order").disabled = byId("view-mode").value === "products";
        byId("routine-controls").hidden = view !== "processes" || !settings.groupContext;
        byId("view-title").textContent = {lineage: "Data lineage", catalogue: "Product catalogue", processes: "Processing map"}[view];
        byId("summary").textContent = graph.nodes.length + " visible nodes · " + graph.edges.filter(edge => edge.kind === "data").length + " data dependencies";
        const named = catalogueGraph.nodes.filter(node => !node.head);
        byId("count-products").textContent = named.length;
        byId("count-outputs").textContent = named.filter(node => node.final && !node.external).length;
        byId("count-temporary").textContent = named.filter(node => node.temporary).length;
        byId("count-processes").textContent = model.nodes.filter(node => node.kind === "action" && (settings.showSkipped || node.active)).length;
        byId("focus-control").hidden = !focus;
        if (focus) byId("focus-label").textContent = nodeLabel(originals.get(focus.id)) + " · " + focus.direction;
        const routineList = byId("routine-list");
        routineList.replaceChildren();
        for (const group of byId("routine-controls").hidden ? [] : model.groups) {
          if (group.id === "root") continue;
          const button = element("button", undefined, "routine");
          button.dataset.group = group.id;
          button.setAttribute("aria-expanded", String(!collapsed.has(group.id)));
          button.style.marginLeft = Math.min(group.number.split(".").length - 1, 5) * 8 + "px";
          button.style.width = "calc(100% - " + button.style.marginLeft + ")";
          button.append(element("span", collapsed.has(group.id) ? "+" : "−", "symbol"));
          const label = element("span");
          label.append(element("strong", group.label), element("small", "Call " + group.number + " · " + group.actions.length + " operations"));
          button.append(label);
          button.addEventListener("click", () => toggle(group.id));
          routineList.append(button);
        }
        const defs = svgElement("defs");
        for (const [id, colour] of [["data-arrow", "#647d99"], ["order-arrow", "#a5b1c0"]]) {
          const marker = svgElement("marker", {id, viewBox: "0 0 10 10", refX: 9,
            refY: 5, markerWidth: 6, markerHeight: 6, orient: "auto-start-reverse"});
          marker.append(svgElement("path", {d: "M 0 0 L 10 5 L 0 10 z", fill: colour}));
          defs.append(marker);
        }
        svg.replaceChildren(defs);
        for (const column of layout.columns) {
          const band = svgElement("g", {class: "dependency-column"});
          band.append(svgElement("rect", {x: column.x, y: 20, width: column.width, height: layout.height - 40, rx: 12}),
            svgElement("text", {x: column.x + 16, y: 46}, column.label));
          svg.append(band);
        }
        for (const lane of layout.lanes) {
          const band = svgElement("g", {class: "lane"});
          band.append(svgElement("rect", {x: 16, y: lane.y, width: layout.width - 32, height: lane.height, rx: 12}));
          band.append(svgElement("text", {x: 32, y: lane.y + 23}, scope(lane.group)));
          if (lane.group !== "root") {
            band.dataset.group = lane.group;
            band.addEventListener("dblclick", () => toggle(lane.group));
          }
          svg.append(band);
        }
        for (const edge of graph.edges) {
          const start = layout.positions.get(edge.source), end = layout.positions.get(edge.target);
          const x1 = start.x + start.width, y1 = start.y + start.height / 2;
          const x2 = end.x, y2 = end.y + end.height / 2;
          const bend = Math.max(36, (x2 - x1) / 2);
          const path = "M" + x1 + "," + y1 + " C" + (x1 + bend) + "," + y1 + " " + (x2 - bend) + "," + y2 + " " + x2 + "," + y2;
          const line = svgElement("path", {d: path, class: "edge " + edge.kind,
            "marker-end": "url(#" + (edge.kind === "order" ? "order-arrow" : "data-arrow") + ")"});
          line.dataset.edge = edge.id;
          line.append(svgElement("title", {}, edge.via.length ? edge.via.join(" → ") : edge.kind === "order" ? "Execution order" : "Data dependency"));
          const hit = svgElement("path", {d: path, class: "edge-hit", tabindex: 0, role: "button",
            "aria-label": edge.kind + " connection from " + edge.source + " to " + edge.target});
          hit.addEventListener("click", () => selectEdge(edge));
          hit.addEventListener("keydown", event => {
            if (event.key === "Enter" || event.key === " ") {event.preventDefault(); selectEdge(edge);}
          });
          svg.append(line, hit);
        }
        for (const node of graph.nodes) {
          const position = layout.positions.get(node.id);
          const control = node.kind === "action" && node.operation !== "script";
          const box = svgElement("g", {
            class: "node " + node.kind + (node.kind === "product" ? " status-" + productStatus(node) : "") +
              (control ? " control" : "") + (!node.active ? " skipped" : ""),
            transform: "translate(" + position.x + "," + position.y + ")",
            tabindex: 0, role: "button", "aria-label": nodeLabel(node) +
              (node.kind === "product" ? ", " + statusLabels[productStatus(node)] :
                node.kind === "group" ? ", call " + node.number : ", operation " + node.order)
          });
          box.dataset.node = node.id;
          box.append(svgElement("rect", {width: position.width, height: position.height, rx: 10}),
            svgElement("rect", {class: "accent", x: 0, y: 12, width: 4, height: position.height - 24, rx: 2}));
          const state = node.kind === "product" ? statusLabels[productStatus(node)] : node.kind === "group" ? "Subroutine context" : control ? "Data handling" : "Processing";
          box.append(svgElement("text", {x: 16, y: 22, class: "node-status"}, state.toUpperCase()));
          const label = node.head && node.final && !node.external ? "Final DATAHEAD" : node.label;
          wrap(label, 29).slice(0, 2).forEach((line, index) => box.append(svgElement("text", {x: 16, y: 43 + index * 17}, line)));
          let subtitle;
          if (node.kind === "group") subtitle = "Call " + node.number + " · " + node.count + " operations · double-click to expand";
          else if (node.kind === "product") subtitle = "Version " + node.version + " · " + node.id +
            (node.pre_resume ? " · pre-resume" : node.created_by ? " · operation " + originals.get(node.created_by).order : " · source data");
          else subtitle = "Operation " + node.order + (settings.groupContext ? " · " + scope(node.group) : "");
          box.append(svgElement("text", {x: 16, y: position.height - 16, class: "subtitle"}, subtitle.length > 41 ? subtitle.slice(0, 38) + "…" : subtitle));
          box.append(svgElement("title", {}, label + "\n" + subtitle));
          box.addEventListener("click", () => selectNode(node));
          box.addEventListener("dblclick", () => {if (node.kind === "group") toggle(node.group);});
          box.addEventListener("keydown", event => {
            if (event.key === "Enter" || event.key === " ") {
              event.preventDefault();
              if (node.kind === "group" && event.key === "Enter") toggle(node.group); else selectNode(node);
            }
          });
          if (selected && selected.kind === "node" && selected.id === node.id) box.classList.add("selected");
          svg.append(box);
        }
        renderMinimap();
        if (view !== "catalogue") {
          if (resetCamera || !camera) readable(); else updateCamera();
        }
        updateSearch();
      } catch (error) {
        svg.replaceChildren();
        byId("error").hidden = false;
        byId("error").textContent = "Unable to render pipeline: " + error.message;
        console.error(error);
      }
    }
    for (const id of ["view-mode", "show-head", "show-order", "show-skipped", "group-context", "product-scope"]) {
      byId(id).addEventListener("change", () => {
        focus = null;
        if (id === "product-scope") byId("group-context").checked = false;
        redraw(true);
      });
    }
    const tabs = Array.from(document.querySelectorAll("[data-view]"));
    for (const [index, tab] of tabs.entries()) {
      tab.addEventListener("click", () => setView(tab.dataset.view));
      tab.addEventListener("keydown", event => {
        if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
        event.preventDefault();
        const next = event.key === "Home" ? 0 : event.key === "End" ? tabs.length - 1 :
          (index + (event.key === "ArrowRight" ? 1 : tabs.length - 1)) % tabs.length;
        setView(tabs[next].dataset.view); tabs[next].focus();
      });
    }
    byId("metric-products").addEventListener("click", () => {focus = null; byId("product-scope").value = "all"; setView("catalogue");});
    byId("metric-outputs").addEventListener("click", () => {focus = null; byId("product-scope").value = "output"; setView("catalogue");});
    byId("metric-temporary").addEventListener("click", () => {focus = null; byId("product-scope").value = "temporary"; setView("catalogue");});
    byId("metric-processes").addEventListener("click", () => {focus = null; byId("product-scope").value = "all"; setView("processes");});
    byId("clear-focus").addEventListener("click", () => {focus = null; redraw(true);});
    byId("sort-products").addEventListener("change", renderCatalogue);
    byId("minimap").addEventListener("click", event => {
      const mini = byId("minimap"), point = mini.createSVGPoint();
      point.x = event.clientX; point.y = event.clientY;
      const local = point.matrixTransform(mini.getScreenCTM().inverse());
      camera.x = Math.max(0, Math.min(layout.width, local.x)) - camera.width / 2;
      camera.y = Math.max(0, Math.min(layout.height, local.y)) - camera.height / 2;
      updateCamera();
    });
    byId("minimap").addEventListener("keydown", event => {
      if (event.key === "Enter" || event.key === " ") {event.preventDefault(); fit();}
    });
    byId("expand-all").addEventListener("click", () => {collapsed.clear(); redraw(true);});
    byId("collapse-all").addEventListener("click", () => {
      for (const group of model.groups) if (group.id !== "root") collapsed.add(group.id);
      redraw(true);
    });
    byId("search").addEventListener("input", updateSearch);
    byId("fit").addEventListener("click", fit);
    byId("readable").addEventListener("click", readable);
    byId("zoom-in").addEventListener("click", () => zoom(0.8));
    byId("zoom-out").addEventListener("click", () => zoom(1.25));
    svg.addEventListener("pointerdown", event => {
      if (event.button !== 0 || event.target.closest("[data-node],.edge-hit")) return;
      const point = svg.createSVGPoint();
      point.x = event.clientX; point.y = event.clientY;
      const local = point.matrixTransform(svg.getScreenCTM().inverse());
      drag = {x: local.x, y: local.y, camera: Object.assign({}, camera)};
      svg.setPointerCapture(event.pointerId);
    });
    svg.addEventListener("pointermove", event => {
      if (!drag) return;
      const point = svg.createSVGPoint();
      point.x = event.clientX; point.y = event.clientY;
      const local = point.matrixTransform(svg.getScreenCTM().inverse());
      camera.x -= local.x - drag.x; camera.y -= local.y - drag.y;
      updateCamera();
    });
    for (const type of ["pointerup", "pointercancel"]) svg.addEventListener(type, () => {drag = null;});
    svg.addEventListener("wheel", event => {
      event.preventDefault();
      if (event.ctrlKey) zoom(event.deltaY < 0 ? 0.88 : 1.14);
      else {
        const scale = camera.width / Math.max(svg.clientWidth, 1);
        camera.x += event.deltaX * scale; camera.y += event.deltaY * scale;
        updateCamera();
      }
    }, {passive: false});
    function download(contents, type, suffix) {
      const url = URL.createObjectURL(new Blob([contents], {type}));
      const link = element("a");
      link.href = url; link.download = model.pipeline.replace(/[^a-zA-Z0-9_.-]/g, "_") + suffix;
      link.click();
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    }
    byId("download-json").addEventListener("click", () => download(JSON.stringify(model, null, 2), "application/json", "_graph.json"));
    byId("download-svg").addEventListener("click", () => {
      const copy = svg.cloneNode(true);
      copy.setAttribute("viewBox", "0 0 " + layout.width + " " + layout.height);
      copy.setAttribute("width", layout.width); copy.setAttribute("height", layout.height);
      const style = svgElement("style", {}, byId("graph-styles").textContent);
      copy.insertBefore(style, copy.firstChild);
      download(new XMLSerializer().serializeToString(copy), "image/svg+xml", "_graph.svg");
    });
    redraw(true);
  } catch (error) {
    byId("error").hidden = false;
    byId("error").textContent = "Unable to load pipeline metadata: " + error.message;
    console.error(error);
  }
})(typeof globalThis === "undefined" ? this : globalThis);
