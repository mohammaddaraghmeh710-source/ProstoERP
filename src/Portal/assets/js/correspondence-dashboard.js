(function () {
  'use strict';
  function initialize() {
    document.querySelectorAll('[data-correspondence-donut]').forEach(function (node) {
      if (node.dataset.chartReady) return;
      var data;
      try { data = JSON.parse(node.getAttribute('data-correspondence-donut')); } catch (ignore) { return; }
      var total = data.series.reduce(function (sum, value) { return sum + value; }, 0);
      if (!total) { node.className = 'text-center text-muted py-5'; node.textContent = 'لا توجد مراسلات لعرضها.'; return; }
      if (!window.ApexCharts) { node.textContent = data.labels.map(function (label, index) { return label + ': ' + data.series[index]; }).join('، '); return; }
      var dark = typeof isDarkStyle !== 'undefined' && isDarkStyle;
      var theme = window.config && (dark ? config.colors_dark : config.colors);
      var palette = { primary: '#5a8dee', success: '#39da8a', danger: '#ff5b5c', info: '#00cfe8', warning: '#fdac41', secondary: '#69809a' };
      var textColor = theme && theme.axisColor || getComputedStyle(document.body).color;
      var options = {
        chart: { type: 'donut', height: 330, fontFamily: getComputedStyle(document.body).fontFamily, toolbar: { show: false }, parentHeightOffset: 0 },
        labels: data.labels,
        series: data.series,
        colors: data.colors.map(function (color) { return theme && theme[color] || palette[color]; }),
        stroke: { show: false },
        dataLabels: { enabled: true, formatter: function (percent) { return percent >= 4 ? Math.round(percent) + '%' : ''; } },
        legend: { show: true, position: 'bottom', horizontalAlign: 'center', fontSize: '13px', labels: { colors: textColor, useSeriesColors: false }, itemMargin: { horizontal: 8, vertical: 5 } },
        tooltip: { y: { formatter: function (value) { return value.toLocaleString('en-US') + ' مراسلة'; } } },
        plotOptions: { pie: { donut: { size: '70%', labels: {
          show: true,
          name: { fontSize: '14px', color: textColor },
          value: { fontSize: '24px', color: textColor, formatter: function (value) { return Number(value).toLocaleString('en-US'); } },
          total: { show: true, showAlways: true, label: 'الإجمالي', fontSize: '14px', color: textColor, formatter: function () { return total.toLocaleString('en-US'); } }
        } } } },
        responsive: [{ breakpoint: 576, options: { chart: { height: 300 }, legend: { position: 'bottom', fontSize: '12px', itemMargin: { horizontal: 5, vertical: 4 } } } }]
      };
      node.dataset.chartReady = '1';
      new ApexCharts(node, options).render();
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', initialize); else initialize();
}());
