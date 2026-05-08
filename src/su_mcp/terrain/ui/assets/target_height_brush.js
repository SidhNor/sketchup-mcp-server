(function () {
  const controls = ['targetElevation', 'radius', 'blendDistance', 'falloff'];

  function readSettings() {
    return {
      targetElevation: numberValue('targetElevation'),
      radius: numberValue('radius'),
      blendDistance: numberValue('blendDistance'),
      falloff: document.getElementById('falloff').value
    };
  }

  function numberValue(id) {
    const value = document.getElementById(id).value;
    return value === '' ? null : Number(value);
  }

  function applyState(state) {
    if (state.targetElevation !== null && state.targetElevation !== undefined) {
      document.getElementById('targetElevation').value = state.targetElevation;
    }
    if (state.radius !== undefined) {
      document.getElementById('radius').value = state.radius;
    }
    if (state.blendDistance !== undefined) {
      document.getElementById('blendDistance').value = state.blendDistance;
    }
    if (state.falloff) {
      document.getElementById('falloff').value = state.falloff;
    }
    document.getElementById('mode').textContent = state.mode || 'target_height';
    document.getElementById('status').textContent = state.status || 'Ready';
    document.getElementById('selectedTerrain').textContent = state.selectedTerrain || 'No terrain selected';
  }

  function sendSettings() {
    if (window.sketchup && window.sketchup.updateSettings) {
      window.sketchup.updateSettings(JSON.stringify(readSettings()));
    }
  }

  controls.forEach(function (id) {
    document.addEventListener('DOMContentLoaded', function () {
      document.getElementById(id).addEventListener('change', sendSettings);
    });
  });

  document.addEventListener('DOMContentLoaded', function () {
    if (window.sketchup && window.sketchup.ready) {
      window.sketchup.ready();
    }
  });

  window.suMcpTerrainBrush = {
    applyState: applyState
  };
}());
