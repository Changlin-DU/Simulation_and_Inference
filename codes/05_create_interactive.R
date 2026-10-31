# ============================================================
# Part 4B: Standalone interactive bootstrap demonstration
#
# The generated HTML allows readers to change:
# 1. Sample size
# 2. Number of bootstrap resamples
# 3. Confidence level
# 4. True population mean
#
# The HTML runs entirely in the reader's browser.
# No R server or Shiny application is required.
# ============================================================


# ------------------------------------------------------------
# 1. Confirm the project location
# ------------------------------------------------------------

project_root <- normalizePath(
  getwd(),
  winslash = "/",
  mustWork = TRUE
)

rproj_files <- list.files(
  path = ".",
  pattern = "\\.Rproj$"
)

if (
  length(rproj_files) == 0 ||
  !dir.exists("codes") ||
  !dir.exists("data") ||
  !dir.exists("results")
) {
  stop(
    paste0(
      "The project root was not detected correctly.\n",
      "Current working directory:\n",
      project_root,
      "\n\nOpen the correct RStudio project and run Source again."
    )
  )
}

message("Project root confirmed: ", project_root)


# ------------------------------------------------------------
# 2. Confirm output directories
# ------------------------------------------------------------

required_directories <- c(
  "data/generated",
  "results/interactive"
)

for (directory in required_directories) {
  if (!dir.exists(directory)) {
    dir.create(
      directory,
      recursive = TRUE,
      showWarnings = FALSE
    )
  }
}


# ------------------------------------------------------------
# 3. Save the default interactive settings
# ------------------------------------------------------------

interactive_defaults <- data.frame(
  setting = c(
    "sample_size",
    "bootstrap_resamples",
    "confidence_level",
    "true_population_mean",
    "population_log_sd",
    "initial_seed"
  ),
  value = c(
    50,
    2000,
    0.95,
    10,
    0.60,
    6400
  )
)

utils::write.csv(
  interactive_defaults,
  file = "data/generated/interactive_default_settings.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 4. Create the standalone HTML
# ------------------------------------------------------------

html_content <- r"---(
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta
    name="viewport"
    content="width=device-width, initial-scale=1.0"
  >
  <title>Interactive Bootstrap Explorer</title>

  <style>
    :root {
      --navy: #17324d;
      --navy-light: #34526d;
      --blue: #7db7d8;
      --blue-dark: #174a6e;
      --green: #009e73;
      --orange: #d55e00;
      --background: #f4f7fa;
      --panel: #ffffff;
      --border: #d9e2ea;
      --muted: #607080;
      --shadow: 0 12px 30px rgba(23, 50, 77, 0.10);
    }

    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      padding: 0;
      color: var(--navy);
      background:
        linear-gradient(
          135deg,
          #eef5f9 0%,
          #f8fafc 45%,
          #eef3f7 100%
        );
      font-family:
        -apple-system,
        BlinkMacSystemFont,
        "Segoe UI",
        Arial,
        sans-serif;
      line-height: 1.5;
    }

    .page {
      width: min(1180px, calc(100% - 32px));
      margin: 28px auto 48px auto;
    }

    .hero {
      padding: 30px 34px;
      margin-bottom: 22px;
      color: white;
      background:
        linear-gradient(
          120deg,
          #17324d 0%,
          #245579 60%,
          #277da1 100%
        );
      border-radius: 18px;
      box-shadow: var(--shadow);
    }

    .hero h1 {
      margin: 0 0 8px 0;
      font-size: clamp(29px, 4vw, 46px);
      line-height: 1.12;
      letter-spacing: -0.03em;
    }

    .hero p {
      max-width: 850px;
      margin: 0;
      color: rgba(255, 255, 255, 0.88);
      font-size: 17px;
    }

    .layout {
      display: grid;
      grid-template-columns: 290px minmax(0, 1fr);
      gap: 22px;
      align-items: start;
    }

    .panel {
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 16px;
      box-shadow: var(--shadow);
    }

    .controls {
      padding: 24px;
      position: sticky;
      top: 18px;
    }

    .controls h2,
    .chart-panel h2 {
      margin: 0;
      color: var(--navy);
    }

    .controls h2 {
      margin-bottom: 5px;
      font-size: 22px;
    }

    .control-intro {
      margin: 0 0 22px 0;
      color: var(--muted);
      font-size: 13px;
    }

    .control {
      margin-bottom: 22px;
    }

    .control-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      gap: 10px;
      margin-bottom: 8px;
    }

    .control label {
      color: var(--navy);
      font-size: 14px;
      font-weight: 700;
    }

    .control-value {
      min-width: 52px;
      padding: 3px 8px;
      text-align: center;
      color: var(--blue-dark);
      background: #eaf4f9;
      border-radius: 7px;
      font-size: 13px;
      font-weight: 800;
    }

    input[type="range"] {
      width: 100%;
      accent-color: #277da1;
      cursor: pointer;
    }

    .range-labels {
      display: flex;
      justify-content: space-between;
      color: #8995a1;
      font-size: 11px;
    }

    .button-row {
      display: grid;
      gap: 10px;
      margin-top: 8px;
    }

    button {
      width: 100%;
      padding: 11px 14px;
      border-radius: 9px;
      font-size: 14px;
      font-weight: 800;
      cursor: pointer;
      transition:
        transform 120ms ease,
        box-shadow 120ms ease,
        opacity 120ms ease;
    }

    button:hover {
      transform: translateY(-1px);
    }

    button:disabled {
      cursor: wait;
      opacity: 0.65;
      transform: none;
    }

    .primary-button {
      color: white;
      background: #277da1;
      border: 1px solid #277da1;
      box-shadow: 0 5px 13px rgba(39, 125, 161, 0.20);
    }

    .secondary-button {
      color: var(--navy);
      background: white;
      border: 1px solid #aebfcd;
    }

    .seed-line {
      margin: 15px 0 0 0;
      color: var(--muted);
      font-size: 12px;
      text-align: center;
    }

    .chart-panel {
      padding: 25px 25px 20px 25px;
      overflow: hidden;
    }

    .chart-heading {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 20px;
      margin-bottom: 4px;
    }

    .chart-heading h2 {
      font-size: 25px;
    }

    .chart-subtitle {
      margin: 3px 0 0 0;
      color: var(--muted);
      font-size: 14px;
    }

    .status {
      flex: 0 0 auto;
      padding: 6px 11px;
      color: #146c50;
      background: #e3f5ed;
      border: 1px solid #b8e4d2;
      border-radius: 999px;
      font-size: 12px;
      font-weight: 800;
    }

    .status.busy {
      color: #8a4c00;
      background: #fff2df;
      border-color: #f1d2a4;
    }

    .canvas-wrap {
      position: relative;
      width: 100%;
      margin-top: 10px;
    }

    canvas {
      display: block;
      width: 100%;
      height: 430px;
      background: white;
      border-radius: 10px;
    }

    .legend {
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      gap: 12px 22px;
      padding: 7px 0 2px 0;
      color: #465665;
      font-size: 12px;
    }

    .legend-item {
      display: inline-flex;
      align-items: center;
      gap: 7px;
    }

    .line-swatch {
      width: 26px;
      height: 0;
      border-top-width: 3px;
      border-top-style: solid;
    }

    .sample-swatch {
      border-top-color: #222222;
    }

    .truth-swatch {
      border-top-color: var(--green);
      border-top-style: dashed;
    }

    .ci-swatch {
      border-top-color: var(--orange);
      border-top-style: dashed;
    }

    .stats {
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 12px;
      margin-top: 17px;
    }

    .stat-card {
      min-width: 0;
      padding: 14px;
      background: #f7fafc;
      border: 1px solid var(--border);
      border-radius: 11px;
    }

    .stat-label {
      margin-bottom: 5px;
      color: var(--muted);
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 0.04em;
      text-transform: uppercase;
    }

    .stat-value {
      overflow: hidden;
      color: var(--navy);
      font-size: clamp(17px, 2vw, 23px);
      font-weight: 800;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .interpretation {
      padding: 17px 19px;
      margin-top: 18px;
      color: #34495a;
      background: #f5f9fc;
      border-left: 5px solid #277da1;
      border-radius: 9px;
      font-size: 14px;
    }

    .interpretation strong {
      color: var(--navy);
    }

    .footer-note {
      margin-top: 14px;
      color: #778795;
      font-size: 11px;
      text-align: center;
    }

    @media (max-width: 900px) {
      .layout {
        grid-template-columns: 1fr;
      }

      .controls {
        position: static;
      }

      .stats {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }
    }

    @media (max-width: 540px) {
      .page {
        width: min(100% - 18px, 1180px);
        margin-top: 10px;
      }

      .hero,
      .controls,
      .chart-panel {
        border-radius: 12px;
      }

      .hero {
        padding: 23px 20px;
      }

      .chart-heading {
        display: block;
      }

      .status {
        display: inline-block;
        margin-top: 9px;
      }

      .stats {
        grid-template-columns: 1fr 1fr;
      }

      canvas {
        height: 390px;
      }
    }
  </style>
</head>

<body>
  <main class="page">
    <section class="hero">
      <h1>Interactive Bootstrap Explorer</h1>
      <p>
        Draw one sample, repeatedly resample from it with replacement,
        and watch how sample size, resampling effort, confidence level,
        and the true population mean affect statistical uncertainty.
      </p>
    </section>

    <section class="layout">
      <aside class="panel controls">
        <h2>Simulation controls</h2>
        <p class="control-intro">
          Adjust the settings, then run the bootstrap simulation.
        </p>

        <div class="control">
          <div class="control-header">
            <label for="sample-size">Sample size</label>
            <span class="control-value" id="sample-size-value">50</span>
          </div>
          <input
            id="sample-size"
            type="range"
            min="20"
            max="200"
            step="10"
            value="50"
          >
          <div class="range-labels">
            <span>20</span>
            <span>200</span>
          </div>
        </div>

        <div class="control">
          <div class="control-header">
            <label for="bootstrap-count">Bootstrap resamples</label>
            <span class="control-value" id="bootstrap-count-value">2,000</span>
          </div>
          <input
            id="bootstrap-count"
            type="range"
            min="200"
            max="5000"
            step="200"
            value="2000"
          >
          <div class="range-labels">
            <span>200</span>
            <span>5,000</span>
          </div>
        </div>

        <div class="control">
          <div class="control-header">
            <label for="confidence-level">Confidence level</label>
            <span class="control-value" id="confidence-level-value">95%</span>
          </div>
          <input
            id="confidence-level"
            type="range"
            min="80"
            max="99"
            step="1"
            value="95"
          >
          <div class="range-labels">
            <span>80%</span>
            <span>99%</span>
          </div>
        </div>

        <div class="control">
          <div class="control-header">
            <label for="true-mean">True population mean</label>
            <span class="control-value" id="true-mean-value">10.0</span>
          </div>
          <input
            id="true-mean"
            type="range"
            min="5"
            max="20"
            step="0.5"
            value="10"
          >
          <div class="range-labels">
            <span>5</span>
            <span>20</span>
          </div>
        </div>

        <div class="button-row">
          <button
            class="primary-button"
            id="run-button"
            type="button"
          >
            Run bootstrap simulation
          </button>

          <button
            class="secondary-button"
            id="new-sample-button"
            type="button"
          >
            Draw a new random sample
          </button>
        </div>

        <p class="seed-line">
          Reproducible browser seed:
          <strong id="seed-value">6400</strong>
        </p>
      </aside>

      <section class="panel chart-panel">
        <div class="chart-heading">
          <div>
            <h2>Bootstrap distribution</h2>
            <p class="chart-subtitle">
              Each bar summarizes bootstrap sample means.
            </p>
          </div>

          <div class="status" id="status">
            Ready
          </div>
        </div>

        <div class="canvas-wrap">
          <canvas
            id="bootstrap-chart"
            aria-label="Interactive histogram of bootstrap sample means"
          ></canvas>
        </div>

        <div class="legend" aria-label="Chart legend">
          <span class="legend-item">
            <span class="line-swatch sample-swatch"></span>
            Observed sample mean
          </span>

          <span class="legend-item">
            <span class="line-swatch truth-swatch"></span>
            True population mean
          </span>

          <span class="legend-item">
            <span class="line-swatch ci-swatch"></span>
            Confidence interval bounds
          </span>
        </div>

        <div class="stats">
          <div class="stat-card">
            <div class="stat-label">Sample mean</div>
            <div class="stat-value" id="sample-mean-stat">—</div>
          </div>

          <div class="stat-card">
            <div class="stat-label">Bootstrap standard error</div>
            <div class="stat-value" id="standard-error-stat">—</div>
          </div>

          <div class="stat-card">
            <div class="stat-label">Bootstrap interval</div>
            <div class="stat-value" id="confidence-interval-stat">—</div>
          </div>

          <div class="stat-card">
            <div class="stat-label">Contains true mean?</div>
            <div class="stat-value" id="coverage-stat">—</div>
          </div>
        </div>

        <div class="interpretation" id="interpretation">
          <strong>Interpretation:</strong>
          Run the simulation to construct a bootstrap confidence interval.
        </div>

        <div class="footer-note">
          All samples and bootstrap results are generated locally in your
          browser. No information is sent to a server.
        </div>
      </section>
    </section>
  </main>

  <script>
    "use strict";

    const controls = {
      sampleSize: document.getElementById("sample-size"),
      bootstrapCount: document.getElementById("bootstrap-count"),
      confidenceLevel: document.getElementById("confidence-level"),
      trueMean: document.getElementById("true-mean")
    };

    const valueDisplays = {
      sampleSize: document.getElementById("sample-size-value"),
      bootstrapCount: document.getElementById("bootstrap-count-value"),
      confidenceLevel: document.getElementById("confidence-level-value"),
      trueMean: document.getElementById("true-mean-value")
    };

    const runButton = document.getElementById("run-button");
    const newSampleButton = document.getElementById("new-sample-button");
    const statusElement = document.getElementById("status");
    const seedElement = document.getElementById("seed-value");
    const canvas = document.getElementById("bootstrap-chart");

    const state = {
      seed: 6400,
      latestResult: null
    };

    function formatNumber(value, digits = 3) {
      return Number(value).toLocaleString(
        undefined,
        {
          minimumFractionDigits: digits,
          maximumFractionDigits: digits
        }
      );
    }

    function updateControlDisplays() {
      valueDisplays.sampleSize.textContent =
        Number(controls.sampleSize.value).toLocaleString();

      valueDisplays.bootstrapCount.textContent =
        Number(controls.bootstrapCount.value).toLocaleString();

      valueDisplays.confidenceLevel.textContent =
        controls.confidenceLevel.value + "%";

      valueDisplays.trueMean.textContent =
        Number(controls.trueMean.value).toFixed(1);
    }

    function setBusy(isBusy) {
      runButton.disabled = isBusy;
      newSampleButton.disabled = isBusy;

      statusElement.textContent = isBusy ? "Simulating…" : "Ready";
      statusElement.classList.toggle("busy", isBusy);
    }

    function mulberry32(seed) {
      let current = seed >>> 0;

      return function() {
        current += 0x6D2B79F5;

        let value = current;

        value = Math.imul(
          value ^ (value >>> 15),
          value | 1
        );

        value ^= value + Math.imul(
          value ^ (value >>> 7),
          value | 61
        );

        return (
          (
            value ^ (value >>> 14)
          ) >>> 0
        ) / 4294967296;
      };
    }

    function createNormalGenerator(randomUniform) {
      let spare = null;

      return function() {
        if (spare !== null) {
          const value = spare;
          spare = null;
          return value;
        }

        let u = 0;
        let v = 0;

        while (u === 0) {
          u = randomUniform();
        }

        while (v === 0) {
          v = randomUniform();
        }

        const magnitude = Math.sqrt(
          -2 * Math.log(u)
        );

        const angle = 2 * Math.PI * v;

        spare = magnitude * Math.sin(angle);

        return magnitude * Math.cos(angle);
      };
    }

    function mean(values) {
      let total = 0;

      for (let index = 0; index < values.length; index += 1) {
        total += values[index];
      }

      return total / values.length;
    }

    function standardDeviation(values) {
      const average = mean(values);
      let squaredTotal = 0;

      for (let index = 0; index < values.length; index += 1) {
        const difference = values[index] - average;
        squaredTotal += difference * difference;
      }

      return Math.sqrt(
        squaredTotal / (values.length - 1)
      );
    }

    function quantile(sortedValues, probability) {
      const position =
        (sortedValues.length - 1) * probability;

      const lowerIndex = Math.floor(position);
      const upperIndex = Math.ceil(position);
      const fraction = position - lowerIndex;

      if (lowerIndex === upperIndex) {
        return sortedValues[lowerIndex];
      }

      return (
        sortedValues[lowerIndex] * (1 - fraction) +
        sortedValues[upperIndex] * fraction
      );
    }

    function generateLognormalSample(
      sampleSize,
      trueMean,
      logStandardDeviation,
      normalRandom
    ) {
      const meanLog =
        Math.log(trueMean) -
        0.5 * logStandardDeviation *
        logStandardDeviation;

      const values = new Array(sampleSize);

      for (let index = 0; index < sampleSize; index += 1) {
        values[index] = Math.exp(
          meanLog +
          logStandardDeviation * normalRandom()
        );
      }

      return values;
    }

    function generateBootstrapMeans(
      sample,
      numberOfResamples,
      randomUniform
    ) {
      const sampleSize = sample.length;
      const bootstrapMeans =
        new Array(numberOfResamples);

      for (
        let bootstrapIndex = 0;
        bootstrapIndex < numberOfResamples;
        bootstrapIndex += 1
      ) {
        let total = 0;

        for (
          let sampleIndex = 0;
          sampleIndex < sampleSize;
          sampleIndex += 1
        ) {
          const selectedIndex = Math.floor(
            randomUniform() * sampleSize
          );

          total += sample[selectedIndex];
        }

        bootstrapMeans[bootstrapIndex] =
          total / sampleSize;
      }

      return bootstrapMeans;
    }

    function calculateHistogram(values, numberOfBins) {
      let minimum = Math.min(...values);
      let maximum = Math.max(...values);

      if (minimum === maximum) {
        minimum -= 0.5;
        maximum += 0.5;
      }

      const width = (maximum - minimum) / numberOfBins;
      const counts = new Array(numberOfBins).fill(0);

      for (const value of values) {
        let binIndex = Math.floor(
          (value - minimum) / width
        );

        if (binIndex >= numberOfBins) {
          binIndex = numberOfBins - 1;
        }

        if (binIndex < 0) {
          binIndex = 0;
        }

        counts[binIndex] += 1;
      }

      return {
        minimum,
        maximum,
        width,
        counts
      };
    }

    function drawChart(result) {
      const context = canvas.getContext("2d");
      const devicePixelRatio =
        window.devicePixelRatio || 1;

      const displayWidth =
        canvas.getBoundingClientRect().width;

      const displayHeight =
        window.innerWidth <= 540 ? 390 : 430;

      canvas.width =
        Math.round(displayWidth * devicePixelRatio);

      canvas.height =
        Math.round(displayHeight * devicePixelRatio);

      context.setTransform(
        devicePixelRatio,
        0,
        0,
        devicePixelRatio,
        0,
        0
      );

      context.clearRect(
        0,
        0,
        displayWidth,
        displayHeight
      );

      const margin = {
        top: 25,
        right: 25,
        bottom: 58,
        left: 58
      };

      const plotWidth =
        displayWidth - margin.left - margin.right;

      const plotHeight =
        displayHeight - margin.top - margin.bottom;

      const histogram = calculateHistogram(
        result.bootstrapMeans,
        35
      );

      const referenceMinimum = Math.min(
        histogram.minimum,
        result.trueMean,
        result.sampleMean,
        result.ciLower
      );

      const referenceMaximum = Math.max(
        histogram.maximum,
        result.trueMean,
        result.sampleMean,
        result.ciUpper
      );

      const referenceRange =
        referenceMaximum - referenceMinimum || 1;

      const xMinimum =
        referenceMinimum - 0.06 * referenceRange;

      const xMaximum =
        referenceMaximum + 0.06 * referenceRange;

      const maximumCount = Math.max(
        ...histogram.counts
      );

      function xPosition(value) {
        return (
          margin.left +
          (
            (value - xMinimum) /
            (xMaximum - xMinimum)
          ) * plotWidth
        );
      }

      function yPosition(count) {
        return (
          margin.top +
          plotHeight -
          (count / maximumCount) * plotHeight * 0.93
        );
      }

      context.strokeStyle = "#dfe6ec";
      context.lineWidth = 1;
      context.fillStyle = "#637482";
      context.font = "12px Arial";
      context.textAlign = "right";
      context.textBaseline = "middle";

      for (let tick = 0; tick <= 4; tick += 1) {
        const count =
          (maximumCount / 4) * tick;

        const y = yPosition(count);

        context.beginPath();
        context.moveTo(margin.left, y);
        context.lineTo(
          margin.left + plotWidth,
          y
        );
        context.stroke();

        context.fillText(
          Math.round(count).toLocaleString(),
          margin.left - 9,
          y
        );
      }

      const visibleBinWidth =
        xPosition(histogram.minimum + histogram.width) -
        xPosition(histogram.minimum);

      for (
        let binIndex = 0;
        binIndex < histogram.counts.length;
        binIndex += 1
      ) {
        const binStart =
          histogram.minimum +
          binIndex * histogram.width;

        const x = xPosition(binStart);
        const y = yPosition(
          histogram.counts[binIndex]
        );

        context.fillStyle = "#7db7d8";

        context.fillRect(
          x + 0.5,
          y,
          Math.max(1, visibleBinWidth - 1),
          margin.top + plotHeight - y
        );
      }

      context.strokeStyle = "#17324d";
      context.lineWidth = 1.4;
      context.beginPath();
      context.moveTo(
        margin.left,
        margin.top + plotHeight
      );
      context.lineTo(
        margin.left + plotWidth,
        margin.top + plotHeight
      );
      context.stroke();

      context.textAlign = "center";
      context.textBaseline = "top";
      context.fillStyle = "#526370";
      context.font = "12px Arial";

      const numberOfXTicks = 5;

      for (
        let tick = 0;
        tick <= numberOfXTicks;
        tick += 1
      ) {
        const value =
          xMinimum +
          (
            (xMaximum - xMinimum) /
            numberOfXTicks
          ) * tick;

        const x = xPosition(value);

        context.fillText(
          value.toFixed(1),
          x,
          margin.top + plotHeight + 9
        );
      }

      context.fillStyle = "#17324d";
      context.font = "bold 14px Arial";
      context.fillText(
        "Bootstrap sample mean",
        margin.left + plotWidth / 2,
        displayHeight - 23
      );

      function drawReferenceLine(
        value,
        color,
        dashPattern,
        lineWidth
      ) {
        const x = xPosition(value);

        context.save();
        context.strokeStyle = color;
        context.lineWidth = lineWidth;
        context.setLineDash(dashPattern);
        context.beginPath();
        context.moveTo(x, margin.top);
        context.lineTo(
          x,
          margin.top + plotHeight
        );
        context.stroke();
        context.restore();
      }

      drawReferenceLine(
        result.ciLower,
        "#d55e00",
        [8, 6],
        2.4
      );

      drawReferenceLine(
        result.ciUpper,
        "#d55e00",
        [8, 6],
        2.4
      );

      drawReferenceLine(
        result.trueMean,
        "#009e73",
        [8, 5, 2, 5],
        2.4
      );

      drawReferenceLine(
        result.sampleMean,
        "#222222",
        [],
        2.4
      );
    }

    function updateResults(result) {
      document.getElementById(
        "sample-mean-stat"
      ).textContent = formatNumber(
        result.sampleMean
      );

      document.getElementById(
        "standard-error-stat"
      ).textContent = formatNumber(
        result.bootstrapStandardError
      );

      document.getElementById(
        "confidence-interval-stat"
      ).textContent =
        "[" +
        formatNumber(result.ciLower, 2) +
        ", " +
        formatNumber(result.ciUpper, 2) +
        "]";

      const coverageElement =
        document.getElementById("coverage-stat");

      coverageElement.textContent =
        result.containsTruth ? "Yes" : "No";

      coverageElement.style.color =
        result.containsTruth ? "#087f5b" : "#d55e00";

      const interpretation =
        document.getElementById("interpretation");

      const confidencePercent =
        Math.round(result.confidenceLevel * 100);

      interpretation.innerHTML =
        "<strong>Interpretation:</strong> " +
        "The " +
        confidencePercent +
        "% bootstrap interval is [" +
        formatNumber(result.ciLower, 2) +
        ", " +
        formatNumber(result.ciUpper, 2) +
        "]. It " +
        (
          result.containsTruth
            ? "contains"
            : "does not contain"
        ) +
        " the true population mean of " +
        formatNumber(result.trueMean, 1) +
        ". One interval may cover or miss the truth; the confidence " +
        "level describes the method’s long-run performance across " +
        "repeated samples.";

      drawChart(result);
    }

    function runSimulation() {
      setBusy(true);

      window.setTimeout(
        function() {
          try {
            const sampleSize =
              Number(controls.sampleSize.value);

            const bootstrapCount =
              Number(controls.bootstrapCount.value);

            const confidenceLevel =
              Number(controls.confidenceLevel.value) / 100;

            const trueMean =
              Number(controls.trueMean.value);

            const randomUniform =
              mulberry32(state.seed);

            const normalRandom =
              createNormalGenerator(randomUniform);

            const sample =
              generateLognormalSample(
                sampleSize,
                trueMean,
                0.60,
                normalRandom
              );

            const sampleMean =
              mean(sample);

            const bootstrapMeans =
              generateBootstrapMeans(
                sample,
                bootstrapCount,
                randomUniform
              );

            const sortedBootstrapMeans =
              bootstrapMeans
                .slice()
                .sort(
                  (first, second) => first - second
                );

            const alpha =
              1 - confidenceLevel;

            const ciLower = quantile(
              sortedBootstrapMeans,
              alpha / 2
            );

            const ciUpper = quantile(
              sortedBootstrapMeans,
              1 - alpha / 2
            );

            const bootstrapStandardError =
              standardDeviation(bootstrapMeans);

            const result = {
              sampleSize,
              bootstrapCount,
              confidenceLevel,
              trueMean,
              sampleMean,
              bootstrapMeans,
              bootstrapStandardError,
              ciLower,
              ciUpper,
              containsTruth:
                ciLower <= trueMean &&
                ciUpper >= trueMean
            };

            state.latestResult = result;

            updateResults(result);

            statusElement.textContent =
              "Simulation complete";
          } catch (error) {
            statusElement.textContent =
              "Simulation error";

            console.error(error);

            alert(
              "The simulation could not be completed: " +
              error.message
            );
          } finally {
            setBusy(false);
          }
        },
        20
      );
    }

    Object.values(controls).forEach(
      function(control) {
        control.addEventListener(
          "input",
          updateControlDisplays
        );
      }
    );

    runButton.addEventListener(
      "click",
      runSimulation
    );

    newSampleButton.addEventListener(
      "click",
      function() {
        state.seed += 1;
        seedElement.textContent = state.seed;
        runSimulation();
      }
    );

    window.addEventListener(
      "resize",
      function() {
        if (state.latestResult !== null) {
          drawChart(state.latestResult);
        }
      }
    );

    updateControlDisplays();
    runSimulation();
  </script>
</body>
</html>
)---"


# ------------------------------------------------------------
# 5. Save the standalone HTML
# ------------------------------------------------------------

interactive_output_path <- file.path(
  "results",
  "interactive",
  "bootstrap_explorer.html"
)

writeLines(
  text = html_content,
  con = interactive_output_path,
  useBytes = TRUE
)


# ------------------------------------------------------------
# 6. Verify the generated output
# ------------------------------------------------------------

expected_outputs <- c(
  "data/generated/interactive_default_settings.csv",
  interactive_output_path
)

missing_outputs <- expected_outputs[
  !file.exists(expected_outputs)
]

if (length(missing_outputs) > 0) {
  stop(
    paste0(
      "The following outputs were not created:\n",
      paste(missing_outputs, collapse = "\n")
    )
  )
}

html_size_bytes <- file.info(
  interactive_output_path
)$size

html_size_kilobytes <- (
  html_size_bytes / 1024
)


# ------------------------------------------------------------
# 7. Attempt to open the result in RStudio Viewer
# ------------------------------------------------------------

interactive_absolute_path <- normalizePath(
  interactive_output_path,
  winslash = "/",
  mustWork = TRUE
)

if (
  requireNamespace(
    "rstudioapi",
    quietly = TRUE
  ) &&
  rstudioapi::isAvailable()
) {
  try(
    rstudioapi::viewer(
      interactive_absolute_path
    ),
    silent = TRUE
  )
}


# ------------------------------------------------------------
# 8. Print the verified result
# ------------------------------------------------------------

cat(
  "\n",
  "============================================================\n",
  "PART 4B COMPLETE: INTERACTIVE BOOTSTRAP EXPLORER\n",
  "============================================================\n",
  "Interactive format: Standalone HTML\n",
  "Requires R Server: No\n",
  "Requires Shiny: No\n",
  "Requires an internet connection: No\n\n",
  "Adjustable quantities:\n",
  "- Sample size: 20 to 200\n",
  "- Bootstrap resamples: 200 to 5,000\n",
  "- Confidence level: 80% to 99%\n",
  "- True population mean: 5 to 20\n",
  "- Random sample through the New Sample button\n\n",
  "HTML size: ",
  round(html_size_kilobytes, 1),
  " KB\n\n",
  "Saved outputs:\n",
  paste(expected_outputs, collapse = "\n"),
  "\n\nOpen this file in a browser:\n",
  interactive_absolute_path,
  "\n============================================================\n",
  sep = ""
)