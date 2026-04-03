// TreePanZoom — LiveView hook for SVG pan/zoom/click interaction
const TreePanZoom = {
  mounted() {
    this.svg = this.el;
    this.isPanning = false;
    this.startPoint = { x: 0, y: 0 };
    this.viewBox = this.svg.viewBox.baseVal;

    // Pan: mouse drag
    this.svg.addEventListener("mousedown", (e) => {
      if (e.target.closest("[data-node-id]")) return; // don't pan when clicking nodes
      this.isPanning = true;
      this.startPoint = { x: e.clientX, y: e.clientY };
      this.svg.style.cursor = "grabbing";
    });

    document.addEventListener("mousemove", (e) => {
      if (!this.isPanning) return;
      const dx = (e.clientX - this.startPoint.x) * (this.viewBox.width / this.svg.clientWidth);
      const dy = (e.clientY - this.startPoint.y) * (this.viewBox.height / this.svg.clientHeight);
      this.viewBox.x -= dx;
      this.viewBox.y -= dy;
      this.startPoint = { x: e.clientX, y: e.clientY };
    });

    document.addEventListener("mouseup", () => {
      this.isPanning = false;
      this.svg.style.cursor = "grab";
    });

    // Zoom: scroll wheel
    this.svg.addEventListener("wheel", (e) => {
      e.preventDefault();
      const scale = e.deltaY > 0 ? 1.1 : 0.9;
      const pt = this.svg.createSVGPoint();
      pt.x = e.clientX;
      pt.y = e.clientY;
      const cursor = pt.matrixTransform(this.svg.getScreenCTM().inverse());

      this.viewBox.x = cursor.x - (cursor.x - this.viewBox.x) * scale;
      this.viewBox.y = cursor.y - (cursor.y - this.viewBox.y) * scale;
      this.viewBox.width *= scale;
      this.viewBox.height *= scale;
    }, { passive: false });

    // Click: node selection
    this.svg.addEventListener("click", (e) => {
      const nodeEl = e.target.closest("[data-node-id]");
      if (nodeEl) {
        this.pushEvent("select_node", { node_id: nodeEl.dataset.nodeId });
      }
    });

    this.svg.style.cursor = "grab";
  },
};

export default TreePanZoom;
