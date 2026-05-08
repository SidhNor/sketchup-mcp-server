(function () {
  const numberControls = [
    'targetElevation',
    'radiusNumber',
    'blendDistanceNumber',
    'strengthNumber',
    'neighborhoodRadiusSamples',
    'iterations'
  ];
  const pairedControls = [
    ['radiusSlider', 'radiusNumber', 'radius', 'meters'],
    ['blendDistanceSlider', 'blendDistanceNumber', 'blendDistance', 'meters'],
    ['strengthSlider', 'strengthNumber', 'strength']
  ];

  function byId(id) {
    return document.getElementById(id);
  }

  function numberValue(id) {
    const value = byId(id).value;
    return value === '' ? null : Number(value);
  }

  function readSettings() {
    return {
      activeTool: byId('mode').dataset.activeTool || 'target_height',
      targetElevation: numberValue('targetElevation'),
      radius: numberValue('radiusNumber'),
      blendDistance: numberValue('blendDistanceNumber'),
      falloff: byId('falloff').value,
      strength: numberValue('strengthNumber'),
      neighborhoodRadiusSamples: numberValue('neighborhoodRadiusSamples'),
      iterations: numberValue('iterations')
    };
  }

  function clampForSlider(input, value) {
    const max = Number(input.max);
    if (Number.isFinite(max) && value > max) {
      return max;
    }
    return value;
  }

  function sliderConfig(slider) {
    return {
      minMeters: Number(slider.dataset.minMeters || slider.min || 0),
      midMeters: Number(slider.dataset.midMeters || 10),
      maxMeters: Number(slider.dataset.maxMeters || slider.max || 100)
    };
  }

  function sliderToMeters(slider) {
    const config = sliderConfig(slider);
    const position = Number(slider.value) / 100;
    if (position <= 0.5) {
      const local = position / 0.5;
      return config.minMeters + ((config.midMeters - config.minMeters) * local * local);
    }
    const local = (position - 0.5) / 0.5;
    return config.midMeters + ((config.maxMeters - config.midMeters) * local * local);
  }

  function metersToSlider(slider, meters) {
    const config = sliderConfig(slider);
    const value = Number(meters);
    if (!Number.isFinite(value)) {
      return 0;
    }
    if (value <= config.midMeters) {
      const span = config.midMeters - config.minMeters;
      const local = span <= 0 ? 0 : Math.sqrt((value - config.minMeters) / span);
      return clampForSlider(slider, local * 50);
    }
    const span = config.maxMeters - config.midMeters;
    const local = span <= 0 ? 0 : Math.sqrt((value - config.midMeters) / span);
    return clampForSlider(slider, 50 + (local * 50));
  }

  function snapMetersForSlider(slider, meters) {
    const config = sliderConfig(slider);
    const snapped = Math.round(Number(meters) * 10) / 10;
    return Math.max(config.minMeters, snapped);
  }

  function setControlValue(id, value) {
    if (value === null || value === undefined) {
      return;
    }
    byId(id).value = value;
  }

  function setSliderValue(sliderId, value) {
    if (value === null || value === undefined) {
      return;
    }
    const slider = byId(sliderId);
    if (slider.dataset.midMeters) {
      slider.value = metersToSlider(slider, value);
    } else {
      slider.value = clampForSlider(slider, Number(value));
    }
  }

  function applyState(state) {
    const activeTool = state.activeTool || state.mode || 'target_height';
    byId('mode').dataset.activeTool = activeTool;
    byId('mode').textContent = activeTool;
    byId('targetHeightPanel').hidden = activeTool !== 'target_height';
    byId('localFairingPanel').hidden = activeTool !== 'local_fairing';

    setControlValue('targetElevation', state.targetElevation);
    setControlValue('radiusNumber', state.radius);
    setSliderValue('radiusSlider', state.radius);
    setControlValue('blendDistanceNumber', state.blendDistance);
    setSliderValue('blendDistanceSlider', state.blendDistance);
    if (state.falloff) {
      byId('falloff').value = state.falloff;
    }

    const fairing = state.localFairing || {};
    setControlValue('strengthNumber', fairing.strength);
    setSliderValue('strengthSlider', fairing.strength);
    setControlValue('neighborhoodRadiusSamples', fairing.neighborhoodRadiusSamples);
    setControlValue('iterations', fairing.iterations);

    const invalid = state.invalidSetting || {};
    numberControls.forEach(function (id) {
      byId(id).setCustomValidity('');
    });
    fieldControlIds(invalid.field).forEach(function (id) {
      byId(id).setCustomValidity(state.status || 'Invalid value');
    });

    byId('status').textContent = state.status || 'Ready';
    byId('selectedTerrain').textContent = state.selectedTerrain || 'No terrain selected';
  }

  function fieldControlIds(field) {
    if (field === 'radius') {
      return ['radiusNumber'];
    }
    if (field === 'blendDistance') {
      return ['blendDistanceNumber'];
    }
    if (field === 'strength') {
      return ['strengthNumber'];
    }
    return field ? [field].filter(function (id) { return byId(id); }) : [];
  }

  function sendSettings(extra) {
    if (window.sketchup && window.sketchup.updateSettings) {
      window.sketchup.updateSettings(JSON.stringify(Object.assign(readSettings(), extra || {})));
    }
  }

  function syncPair(sourceId, targetId, field, scale) {
    const source = byId(sourceId);
    const value = scale === 'meters' ? snapMetersForSlider(source, sliderToMeters(source)) : source.value;
    byId(targetId).value = scale === 'meters' ? value.toFixed(1) : value;
    const extra = {};
    extra[field] = numberValue(targetId);
    if (sourceId.indexOf('Slider') !== -1) {
      extra.source = 'slider';
    }
    sendSettings(extra);
  }

  document.addEventListener('DOMContentLoaded', function () {
    pairedControls.forEach(function (pair) {
      byId(pair[0]).addEventListener('input', function () {
        syncPair(pair[0], pair[1], pair[2], pair[3]);
      });
      byId(pair[1]).addEventListener('change', function () {
        setSliderValue(pair[0], numberValue(pair[1]));
        sendSettings();
      });
    });

    ['targetElevation', 'falloff', 'neighborhoodRadiusSamples', 'iterations'].forEach(function (id) {
      byId(id).addEventListener('change', function () {
        sendSettings();
      });
    });

    if (window.sketchup && window.sketchup.ready) {
      window.sketchup.ready();
    }
  });

  window.suMcpTerrainBrush = {
    applyState: applyState
  };
}());
