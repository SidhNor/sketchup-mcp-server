(function () {
  const numberControls = [
    'targetElevation',
    'radiusNumber',
    'blendDistanceNumber',
    'strengthNumber',
    'neighborhoodRadiusSamples',
    'iterations',
    'corridorStartX',
    'corridorStartY',
    'corridorStartElevation',
    'corridorEndX',
    'corridorEndY',
    'corridorEndElevation',
    'corridorWidth',
    'corridorSideBlendDistance'
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
    normalizeCorridorSideBlendControls();
    return {
      activeTool: byId('mode').dataset.activeTool || 'target_height',
      targetElevation: numberValue('targetElevation'),
      radius: numberValue('radiusNumber'),
      blendDistance: numberValue('blendDistanceNumber'),
      falloff: byId('falloff').value,
      strength: numberValue('strengthNumber'),
      neighborhoodRadiusSamples: numberValue('neighborhoodRadiusSamples'),
      iterations: numberValue('iterations'),
      selectedEndpoint: selectedEndpoint(),
      startControl: {
        point: { x: numberValue('corridorStartX'), y: numberValue('corridorStartY') },
        elevation: numberValue('corridorStartElevation')
      },
      endControl: {
        point: { x: numberValue('corridorEndX'), y: numberValue('corridorEndY') },
        elevation: numberValue('corridorEndElevation')
      },
      width: numberValue('corridorWidth'),
      sideBlend: {
        distance: numberValue('corridorSideBlendDistance'),
        falloff: byId('corridorSideBlendFalloff').value
      }
    };
  }

  function selectedEndpoint() {
    const active = document.activeElement && document.activeElement.id;
    if (active && active.indexOf('corridorStart') === 0) {
      return 'start';
    }
    if (active && active.indexOf('corridorEnd') === 0) {
      return 'end';
    }
    return byId('corridorTransitionPanel').dataset.selectedEndpoint || null;
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

  function sliderToElevation(slider) {
    const minValue = Number(slider.dataset.minElevation || -5);
    const midValue = Number(slider.dataset.midElevation || 0);
    const maxValue = Number(slider.dataset.maxElevation || 5);
    const position = Number(slider.value) / 100;
    if (position <= 0.5) {
      const local = position / 0.5;
      return minValue + ((midValue - minValue) * local * local);
    }
    const local = (position - 0.5) / 0.5;
    return midValue + ((maxValue - midValue) * local * local);
  }

  function elevationToSlider(slider, elevation) {
    const minValue = Number(slider.dataset.minElevation || -5);
    const midValue = Number(slider.dataset.midElevation || 0);
    const maxValue = Number(slider.dataset.maxElevation || 5);
    const value = Number(elevation);
    if (!Number.isFinite(value)) {
      return 50;
    }
    if (value <= midValue) {
      const span = midValue - minValue;
      const ratio = span <= 0 ? 0 : Math.min(1, Math.max(0, (value - minValue) / span));
      const local = Math.sqrt(ratio);
      return Math.min(50, Math.max(0, local * 50));
    }
    const span = maxValue - midValue;
    const ratio = span <= 0 ? 0 : Math.min(1, Math.max(0, (value - midValue) / span));
    const local = Math.sqrt(ratio);
    return Math.min(100, Math.max(50, 50 + (local * 50)));
  }

  function snapMetersForSlider(slider, meters) {
    const config = sliderConfig(slider);
    const snapped = Math.round(Number(meters) * 10) / 10;
    return Math.max(config.minMeters, snapped);
  }

  function setControlValue(id, value) {
    if (value === null || value === undefined) {
      byId(id).value = '';
      return;
    }
    byId(id).value = value;
  }

  function setOptionalSliderValue(slider, value) {
    if (value === null || value === undefined) {
      slider.value = 50;
      return;
    }
    slider.value = value;
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
    byId('roundBrushSharedControls').hidden = activeTool === 'corridor_transition';
    byId('targetHeightPanel').hidden = activeTool !== 'target_height';
    byId('localFairingPanel').hidden = activeTool !== 'local_fairing';
    byId('corridorTransitionPanel').hidden = activeTool !== 'corridor_transition';

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

    const corridor = state.corridor || {};
    const start = corridor.startControl || {};
    const end = corridor.endControl || {};
    byId('corridorTransitionPanel').dataset.selectedEndpoint = corridor.selectedEndpoint || '';
    setControlValue('corridorStartX', start.x);
    setControlValue('corridorStartY', start.y);
    setControlValue('corridorStartElevation', start.elevation);
    setElevationSlider('corridorStartElevationSlider', start.elevation, corridor, 'start');
    setControlValue('corridorEndX', end.x);
    setControlValue('corridorEndY', end.y);
    setControlValue('corridorEndElevation', end.elevation);
    setElevationSlider('corridorEndElevationSlider', end.elevation, corridor, 'end');
    setControlValue('corridorWidth', corridor.width);
    const sideBlend = corridor.sideBlend || {};
    setControlValue('corridorSideBlendDistance', sideBlend.distance);
    if (sideBlend.falloff) {
      byId('corridorSideBlendFalloff').value = sideBlend.falloff;
    }

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

  function setElevationSlider(id, value, corridor, endpoint) {
    const slider = byId(id);
    if (value === null || value === undefined) {
      delete slider.dataset.minElevation;
      delete slider.dataset.midElevation;
      delete slider.dataset.maxElevation;
      setOptionalSliderValue(slider, null);
      return;
    }
    const ranges = corridor.elevationSliderRanges || {};
    const range = ranges[endpoint] || corridor.elevationSliderRange || {};
    if (Number.isFinite(Number(range.min)) && Number.isFinite(Number(range.max))) {
      slider.dataset.minElevation = range.min;
      slider.dataset.midElevation = Number.isFinite(Number(range.mid)) ? range.mid : value;
      slider.dataset.maxElevation = range.max;
    }
    slider.value = elevationToSlider(slider, value);
  }

  function normalizeCorridorSideBlendControls() {
    const distance = numberValue('corridorSideBlendDistance');
    const falloff = byId('corridorSideBlendFalloff');
    if (Number.isFinite(distance) && distance <= 0) {
      falloff.value = 'none';
      return;
    }
    if (Number.isFinite(distance) && distance > 0 && falloff.value === 'none') {
      falloff.value = 'cosine';
    }
  }

  function resetCorridorSideBlendControls() {
    byId('corridorSideBlendDistance').value = '0.0';
    byId('corridorSideBlendFalloff').value = 'none';
    const options = byId('corridorSideBlendOptions');
    if (options) {
      options.open = false;
    }
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
    if (field === 'region.width') {
      return ['corridorWidth'];
    }
    if (field === 'region.sideBlend.distance') {
      return ['corridorSideBlendDistance'];
    }
    if (field === 'region.sideBlend.falloff') {
      return ['corridorSideBlendFalloff'];
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

    [
      'corridorStartX',
      'corridorStartY',
      'corridorStartElevation',
      'corridorEndX',
      'corridorEndY',
      'corridorEndElevation',
      'corridorWidth',
      'corridorSideBlendDistance',
      'corridorSideBlendFalloff'
    ].forEach(function (id) {
      byId(id).addEventListener('change', function () {
        if (id === 'corridorSideBlendDistance' || id === 'corridorSideBlendFalloff') {
          normalizeCorridorSideBlendControls();
        }
        sendSettings();
      });
    });

    [
      ['corridorStartElevationSlider', 'corridorStartElevation', 'start'],
      ['corridorEndElevationSlider', 'corridorEndElevation', 'end']
    ].forEach(function (pair) {
      const slider = byId(pair[0]);
      slider.addEventListener('input', function () {
        const elevation = sliderToElevation(slider);
        byId(pair[1]).value = (Math.round(elevation * 100) / 100).toFixed(2);
        sendSettings({ selectedEndpoint: pair[2], source: 'corridorElevationSlider' });
      });
      slider.addEventListener('change', function () {
        sendSettings({ selectedEndpoint: pair[2] });
      });
    });

    byId('recaptureCorridorStart').addEventListener('click', function () {
      if (window.sketchup && window.sketchup.recaptureCorridorEndpoint) {
        window.sketchup.recaptureCorridorEndpoint('start');
      }
    });
    byId('recaptureCorridorEnd').addEventListener('click', function () {
      if (window.sketchup && window.sketchup.recaptureCorridorEndpoint) {
        window.sketchup.recaptureCorridorEndpoint('end');
      }
    });
    byId('sampleCorridorStart').addEventListener('click', function () {
      if (window.sketchup && window.sketchup.sampleCorridorTerrain) {
        window.sketchup.sampleCorridorTerrain('start');
      }
    });
    byId('sampleCorridorEnd').addEventListener('click', function () {
      if (window.sketchup && window.sketchup.sampleCorridorTerrain) {
        window.sketchup.sampleCorridorTerrain('end');
      }
    });
    byId('resetCorridor').addEventListener('click', function () {
      if (window.sketchup && window.sketchup.resetCorridor) {
        window.sketchup.resetCorridor();
      }
    });
    byId('resetCorridorSideBlend').addEventListener('click', function () {
      resetCorridorSideBlendControls();
      sendSettings();
    });
    byId('applyCorridor').addEventListener('click', function () {
      normalizeCorridorSideBlendControls();
      if (window.sketchup && window.sketchup.applyCorridor) {
        window.sketchup.applyCorridor();
      }
    });

    if (window.sketchup && window.sketchup.ready) {
      window.sketchup.ready();
    }
  });

  window.suMcpTerrainBrush = {
    applyState: applyState
  };
}());
