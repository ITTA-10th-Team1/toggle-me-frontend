import 'dart:convert';

import '../domain/room_data.dart';

String roomSceneBridgeFor(
  List<RoomFurniture> furniture,
) => roomSceneBridge.replaceFirst(
  'const placements = null;',
  'const placements = ${jsonEncode(furniture.map((e) => e.scene).toList())};',
);

/// For model_viewer_plus 1.10.0's bundled model-viewer surface ID format.
/// Uses mesh IDs from the loaded GLB, not screen rectangles or material colors.
const roomSceneBridge = r'''
(() => {
  const room = document.querySelector('model-viewer');
  if (!room || room.dataset.toggleBridge === '5') return;
  room.dataset.toggleBridge = '5';
  const post = (channel, value) => {
    if (globalThis[channel]?.postMessage) globalThis[channel].postMessage(value);
  };
  const meshCategories = new Map();
  const furnitureNodes = {stand: 'mirror', body: 'fridge', desk: 'desk'};
  const placements = null;
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
    if (placements !== null) {
      // model-viewer 1.10's bundled scene graph. Fail explicitly if it changes.
      const key = Object.getOwnPropertySymbols(room).find(s => s.description === 'scene');
      const scene = key && room[key];
      if (!scene?.traverse) { post('RoomStatus', 'error'); return; }
      const nodes = new Map();
      scene.traverse(node => { if (node.name) nodes.set(node.name, node); });
      const applied = new Set();
      for (const item of placements) {
        if (!['mirror', 'fridge', 'desk'].includes(item.furnitureTypeCode)) continue;
        const node = nodes.get(item.objectNodeName);
        if (!node) { post('RoomStatus', 'error'); return; }
        applied.add(item.objectNodeName);
        node.visible = !item.hidden;
        const p = item.position, q = item.rotationQuaternion;
        let s = item.scale;
        // The current bundled GLB already has these old export scales baked in.
        // Accept both legacy rooms and corrected server data during migration.
        const legacy = item.furnitureTypeCode === 'mirror' ? [0.25, 1, 0.55] :
          item.furnitureTypeCode === 'fridge' ? [0.3, 1, 0.55] : null;
        if (legacy && s && [s.x, s.y, s.z].every((v, i) =>
            Number.isFinite(v) && Math.abs(v - legacy[i]) < 0.00001)) {
          const original = json?.nodes?.find(n => n.name === item.objectNodeName);
          if (!original) { post('RoomStatus', 'error'); return; }
          const scale = original.scale || [1, 1, 1];
          s = {x: scale[0], y: scale[1], z: scale[2]};
        }
        const values = [p?.x,p?.y,p?.z,q?.x,q?.y,q?.z,q?.w,s?.x,s?.y,s?.z];
        if (!values.every(Number.isFinite) || Math.hypot(q.x,q.y,q.z,q.w) < 0.000001 ||
            Math.min(s.x,s.y,s.z) <= 0) { post('RoomStatus', 'error'); return; }
        node.position.set(p.x,p.y,p.z);
        node.quaternion.set(q.x,q.y,q.z,q.w).normalize();
        node.scale.set(s.x,s.y,s.z);
        node.traverse(child => { child.renderOrder = item.renderOrder; });
        node.updateMatrixWorld(true);
      }
      // Missing furniture must not remain visible from the bundled GLB.
      for (const name of Object.keys(furnitureNodes)) {
        if (!applied.has(name) && nodes.has(name)) nodes.get(name).visible = false;
      }
      scene.queueRender?.();
    }
    if (json?.nodes) {
      json.nodes.forEach((node, index) => {
        // The desk root owns the chair, drawers and both shelf assemblies.
        const category = furnitureNodes[node.name];
        if (category) mark(json, index, category);
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
