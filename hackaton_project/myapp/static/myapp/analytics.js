console.log(analyticsJson);
const analyticsData = JSON.parse(analyticsJson);

renderAll();
window.onresize = renderAll;

function renderAll() {
    renderAnalytics('Промышленные образцы', 'hist-prom')
    renderAnalytics('Изобретение', 'hist-inv')
    renderAnalytics('Полезная модель', 'hist-model')
}

function renderAnalytics(type, histId) {
    const histData = Object.fromEntries(analyticsData
        .filter(obj => obj.patent_types === type)
        .map(obj => [obj.classific, obj.num_of_patent_by_type]))

    const hist = document.getElementById(histId);
    drawHistogram(hist, histData, 'Классы', 'Количество');
}

function drawHistogram(canvas, data, legendX, legendY) {
    const width = canvas.clientWidth;
    const height = canvas.clientHeight;

    const legendXHeight = 50;
    const legendYWidth = 150;

    const labelXHeight = 30;
    const labelYWidth = 20;

    const axisY = legendYWidth + labelYWidth;
    const axisX = height - legendXHeight - labelXHeight;

    // If it's resolution does not match change it
    if (canvas.width !== width || canvas.height !== height) {
        canvas.width = width;
        canvas.height = height;
    }

    const histWidth = 12;

    let histCount = 10;
    let histGap = (width - axisY) / (histCount + 1);

    if (histGap < 20) {
        histGap = 20;
        histCount = Math.floor((width - axisY) / histGap) - 1;
    }

    const ctx = canvas.getContext("2d");
    // const ctx = CanvasRect();
    ctx.clearRect(0, 0, width, height);

    ctx.font = "20px sans-serif";
    ctx.fillText(legendX, axisY, axisX + labelXHeight + 20);
    ctx.fillText(legendY, 0, 20);

    ctx.strokeStyle = '#d9d9d9';
    ctx.beginPath();
    ctx.moveTo(axisY, 0);
    ctx.lineTo(axisY, axisX);
    ctx.lineTo(width, axisX);
    ctx.stroke();

    const histData = Object.entries(data)
        .slice(0, histCount)
        .map(obj => { return { label: obj[0], value: obj[1] }; })
        .sort((a, b) => b.value - a.value);

    if (histData.length === 0) {
        return;
    }

    const maxY = histData[0].value;
    const maxYPx = axisX - 10;

    let stepY;
    if (maxY < 5) stepY = 1;
    else if (maxY < 20) stepY = 5;
    else stepY = 10;

    let labelsY = [];
    for (let i = stepY; i < maxY; i += stepY) {
        labelsY.push(i);
    }
    labelsY.push(maxY);

    {
        ctx.font = "12px sans-serif";
        for (const label of labelsY) {
            const labelHeight = maxYPx * (label / maxY);
            ctx.fillText(String(label), legendYWidth, axisX - labelHeight + 6, labelYWidth);
        }
    }

    {
        ctx.font = "12px sans-serif";
        ctx.textAlign = "center";
        ctx.fillStyle = "black";
        let histX = axisY + histGap - histWidth / 2;
        for (const obj of histData) {
            ctx.fillText(String(obj.label), histX + histWidth / 2, axisX + 15, histGap);
            histX += histGap;
        }
    }

    {
        ctx.font = "12px sans-serif";
        ctx.fillStyle = "#133c99";
        let histX = axisY + histGap - histWidth / 2;
        for (const obj of histData) {
            const histHeight = maxYPx * (obj.value / maxY);
            ctx.fillRect(histX, axisX - histHeight, histWidth, histHeight);

            ctx.beginPath();
            ctx.arc(histX + histWidth / 2, axisX - histHeight, histWidth / 2, 0, 2 * Math.PI, false);
            ctx.fill();
            histX += histGap;
        }
    }
}
