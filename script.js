// センサーサイズの定義（対角線長をmmで）
const sensorSizes = {
    'full': { width: 36, height: 24, diagonal: 43.27 },
    'aps-c': { width: 23.6, height: 15.7, diagonal: 28.3 },
    'm43': { width: 17.3, height: 13, diagonal: 21.6 }
};

// DOM要素の取得
const distanceInput = document.getElementById('distance');
const groundRatioInput = document.getElementById('groundRatio');
const sensorSizeSelect = document.getElementById('sensorSize');
const fireworksHeightInput = document.getElementById('fireworksHeight');
const lensMmDisplay = document.getElementById('lensMm');
const angleInfo = document.getElementById('angleInfo');
const coverageInfo = document.getElementById('coverageInfo');
const previewCanvas = document.getElementById('previewCanvas');
const previewDistance = document.getElementById('previewDistance');
const previewGroundRatio = document.getElementById('previewGroundRatio');
const previewLens = document.getElementById('previewLens');

// Canvas設定
const ctx = previewCanvas.getContext('2d');
let canvasWidth = previewCanvas.offsetWidth;
let canvasHeight = previewCanvas.offsetHeight;

// Canvasサイズの調整
function resizeCanvas() {
    canvasWidth = previewCanvas.offsetWidth;
    canvasHeight = previewCanvas.offsetHeight;
    previewCanvas.width = canvasWidth;
    previewCanvas.height = canvasHeight;
    drawPreview();
}

window.addEventListener('resize', resizeCanvas);
resizeCanvas();

// レンズmm数の計算
function calculateLensMm(distance, groundRatio, sensorSize, fireworksHeight) {
    // 地上の割合から、花火が占める画面の高さを計算
    const skyRatio = (100 - groundRatio) / 100;
    
    // 花火の高さを画面に収めるために必要な画角を計算
    // 距離と被写体の高さから、必要な画角（垂直方向）を計算
    // 画角 = 2 * arctan(被写体の高さ / (2 * 距離))
    const verticalAngleRad = 2 * Math.atan(fireworksHeight / (2 * distance));
    const verticalAngleDeg = verticalAngleRad * (180 / Math.PI);
    
    // 画面の高さに対する花火の高さの割合を考慮
    // 実際には、花火が画面のskyRatio分を占めるようにする
    const effectiveVerticalAngleRad = verticalAngleRad / skyRatio;
    
    // センサーの垂直サイズと画角からレンズmm数を計算
    // mm = (センサー高さ / 2) / tan(画角 / 2)
    const sensor = sensorSizes[sensorSize];
    const lensMm = (sensor.height / 2) / Math.tan(effectiveVerticalAngleRad / 2);
    
    return Math.round(lensMm);
}

// 画角の計算
function calculateAngle(lensMm, sensorSize) {
    const sensor = sensorSizes[sensorSize];
    const angleRad = 2 * Math.atan(sensor.diagonal / (2 * lensMm));
    const angleDeg = angleRad * (180 / Math.PI);
    return angleDeg;
}

// プレビューの描画
function drawPreview() {
    const distance = parseFloat(distanceInput.value) || 500;
    const groundRatio = parseFloat(groundRatioInput.value) || 30;
    const sensorSize = sensorSizeSelect.value;
    const fireworksHeight = parseFloat(fireworksHeightInput.value) || 300;
    
    const lensMm = calculateLensMm(distance, groundRatio, sensorSize, fireworksHeight);
    
    // 背景をクリア
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);
    
    // 空と地面の境界線を計算
    const groundLineY = canvasHeight * (groundRatio / 100);
    
    // 空の背景（グラデーション）
    const skyGradient = ctx.createLinearGradient(0, 0, 0, groundLineY);
    skyGradient.addColorStop(0, '#1a1a2e');
    skyGradient.addColorStop(0.5, '#16213e');
    skyGradient.addColorStop(1, '#0f3460');
    ctx.fillStyle = skyGradient;
    ctx.fillRect(0, 0, canvasWidth, groundLineY);
    
    // 地面の背景
    const groundGradient = ctx.createLinearGradient(0, groundLineY, 0, canvasHeight);
    groundGradient.addColorStop(0, '#2d5016');
    groundGradient.addColorStop(1, '#1a3009');
    ctx.fillStyle = groundGradient;
    ctx.fillRect(0, groundLineY, canvasWidth, canvasHeight - groundLineY);
    
    // 地平線
    ctx.strokeStyle = '#666';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(0, groundLineY);
    ctx.lineTo(canvasWidth, groundLineY);
    ctx.stroke();
    
    // 花火の描画
    const skyHeight = groundLineY;
    const fireworksCenterX = canvasWidth / 2;
    const fireworksCenterY = skyHeight * 0.7; // 空の70%の位置
    
    // 花火の大きさを距離に応じて調整
    const scale = Math.min(1, 500 / distance);
    const fireworksRadius = Math.min(skyHeight * 0.15 * scale, skyHeight * 0.2);
    
    // 花火の円（複数の円で表現）
    const colors = ['#ff6b6b', '#4ecdc4', '#ffe66d', '#ff8c42', '#95e1d3'];
    for (let i = 0; i < 5; i++) {
        const radius = fireworksRadius * (0.3 + i * 0.15);
        const alpha = 0.6 - i * 0.1;
        ctx.fillStyle = colors[i % colors.length] + Math.floor(alpha * 255).toString(16).padStart(2, '0');
        ctx.beginPath();
        ctx.arc(fireworksCenterX, fireworksCenterY, radius, 0, Math.PI * 2);
        ctx.fill();
    }
    
    // 花火の光線
    ctx.strokeStyle = '#ffe66d';
    ctx.lineWidth = 2;
    for (let i = 0; i < 8; i++) {
        const angle = (Math.PI * 2 * i) / 8;
        const startX = fireworksCenterX + Math.cos(angle) * fireworksRadius * 0.5;
        const startY = fireworksCenterY + Math.sin(angle) * fireworksRadius * 0.5;
        const endX = fireworksCenterX + Math.cos(angle) * fireworksRadius * 1.5;
        const endY = fireworksCenterY + Math.sin(angle) * fireworksRadius * 1.5;
        
        ctx.beginPath();
        ctx.moveTo(startX, startY);
        ctx.lineTo(endX, endY);
        ctx.stroke();
    }
    
    // 撮影位置のマーカー
    const cameraY = canvasHeight - 20;
    ctx.fillStyle = '#fff';
    ctx.beginPath();
    ctx.arc(canvasWidth / 2, cameraY, 8, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = '#333';
    ctx.lineWidth = 2;
    ctx.stroke();
    
    // 距離線の描画
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.3)';
    ctx.lineWidth = 1;
    ctx.setLineDash([5, 5]);
    ctx.beginPath();
    ctx.moveTo(canvasWidth / 2, cameraY);
    ctx.lineTo(fireworksCenterX, fireworksCenterY);
    ctx.stroke();
    ctx.setLineDash([]);
    
    // 距離のラベル
    ctx.fillStyle = 'rgba(255, 255, 255, 0.8)';
    ctx.font = '14px sans-serif';
    ctx.textAlign = 'center';
    const labelX = canvasWidth / 2;
    const labelY = (cameraY + fireworksCenterY) / 2;
    ctx.fillText(`${distance}m`, labelX, labelY);
    
    // 構図のガイドライン（三分割法）
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.2)';
    ctx.lineWidth = 1;
    ctx.setLineDash([3, 3]);
    
    // 垂直線
    for (let i = 1; i < 3; i++) {
        ctx.beginPath();
        ctx.moveTo((canvasWidth / 3) * i, 0);
        ctx.lineTo((canvasWidth / 3) * i, canvasHeight);
        ctx.stroke();
    }
    
    // 水平線
    for (let i = 1; i < 3; i++) {
        ctx.beginPath();
        ctx.moveTo(0, (canvasHeight / 3) * i);
        ctx.lineTo(canvasWidth, (canvasHeight / 3) * i);
        ctx.stroke();
    }
    ctx.setLineDash([]);
    
    // 情報表示の更新
    previewDistance.textContent = distance;
    previewGroundRatio.textContent = groundRatio;
    previewLens.textContent = lensMm;
}

// 計算と表示の更新
function updateCalculation() {
    const distance = parseFloat(distanceInput.value) || 500;
    const groundRatio = parseFloat(groundRatioInput.value) || 30;
    const sensorSize = sensorSizeSelect.value;
    const fireworksHeight = parseFloat(fireworksHeightInput.value) || 300;
    
    const lensMm = calculateLensMm(distance, groundRatio, sensorSize, fireworksHeight);
    const angle = calculateAngle(lensMm, sensorSize);
    
    // レンズmm数の表示
    lensMmDisplay.textContent = lensMm;
    
    // 画角情報の表示
    angleInfo.textContent = `画角: 約${angle.toFixed(1)}度（対角線）`;
    
    // カバレッジ情報の表示
    const skyRatio = 100 - groundRatio;
    coverageInfo.textContent = `空の割合: ${skyRatio}% / 地上の割合: ${groundRatio}%`;
    
    // プレビューの更新
    drawPreview();
}

// イベントリスナーの設定
distanceInput.addEventListener('input', updateCalculation);
groundRatioInput.addEventListener('input', updateCalculation);
sensorSizeSelect.addEventListener('change', updateCalculation);
fireworksHeightInput.addEventListener('input', updateCalculation);

// 初期計算の実行
updateCalculation();
