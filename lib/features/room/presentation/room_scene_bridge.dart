/// For model_viewer_plus 1.10.0's bundled model-viewer surface ID format.
/// Uses mesh IDs from the loaded GLB, not screen rectangles or material colors.
const roomSceneBridge = r'''
(() => {
  const room = document.querySelector('model-viewer');
  if (!room || room.dataset.toggleBridge === '4') return;
  room.dataset.toggleBridge = '4';
  const post = (channel, value) => {
    if (globalThis[channel]?.postMessage) globalThis[channel].postMessage(value);
  };
  const meshCategories = new Map();
  const mark = (json, index, category, visited = new Set()) => {
    if (visited.has(index)) return;
    visited.add(index);
    const node = json.nodes?.[index];
    if (!node) return;
    if (Number.isInteger(node.mesh)) meshCategories.set(node.mesh, category);
    for (const child of node.children || []) mark(json, child, category, visited);
  };
  const lockCamera = () => {
    room.cameraControls = false;
    room.removeAttribute('camera-controls');
    room.autoRotate = false;
    room.disablePan = true;
    room.disableZoom = true;
    room.disableTap = true;
  };
  const onLoad = () => {
    lockCamera();
    meshCategories.clear();
    const json = room.originalGltfJson;
    if (json?.nodes) {
      json.nodes.forEach((node, index) => {
        // Current designer GLB: stand owns mirror and frame;
        // body owns the refrigerator doors and handles.
        if (node.name === 'stand') mark(json, index, 'mirror');
        if (node.name === 'body') mark(json, index, 'fridge');
      });
    }
    post('RoomStatus', 'loaded');
  };
  room.addEventListener('load', onLoad);
  room.addEventListener('error', () => post('RoomStatus', 'error'));
  customElements.whenDefined('model-viewer').then(() => {
    lockCamera();
    if (room.loaded) onLoad();
  });

  const pointers = new Set();
  let tap = null;
  room.addEventListener('pointerdown', event => {
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    pointers.add(event.pointerId);
    if (event.cancelable) event.preventDefault();
    room.setPointerCapture?.(event.pointerId);
    tap = pointers.size === 1 ? {
      id: event.pointerId, x: event.clientX, y: event.clientY,
      at: performance.now(), moved: false,
    } : null;
  }, {passive: false});
  room.addEventListener('pointermove', event => {
    if (event.cancelable) event.preventDefault();
    if (tap?.id === event.pointerId &&
        Math.hypot(event.clientX - tap.x, event.clientY - tap.y) > 8) {
      tap.moved = true;
    }
  }, {passive: false});
  room.addEventListener('pointerup', event => {
    const candidate = tap;
    pointers.delete(event.pointerId);
    tap = null;
    if (!candidate || candidate.id !== event.pointerId || candidate.moved ||
        pointers.size || performance.now() - candidate.at > 600 ||
        Math.hypot(event.clientX - candidate.x, event.clientY - candidate.y) > 8) return;
    if (!room.loaded || typeof room.surfaceFromPoint !== 'function') return;
    // The bundled version returns: mesh primitive vertexA vertexB vertexC baryX baryY baryZ.
    const surface = room.surfaceFromPoint(event.clientX, event.clientY);
    if (typeof surface !== 'string') return;
    const parts = surface.trim().split(/\s+/).map(Number);
    if (parts.length !== 8 || !parts.every(Number.isFinite) || !Number.isInteger(parts[0])) return;
    const category = meshCategories.get(parts[0]);
    if (category) post('RoomFurniture', category);
  });
  const cancel = event => {
    pointers.delete(event.pointerId);
    tap = null;
  };
  room.addEventListener('pointercancel', cancel);
  room.addEventListener('lostpointercapture', cancel);
})();
''';
