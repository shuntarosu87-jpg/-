//
//  SideView.swift
//  FireworksLensCalculator
//
//  Created on 2024
//

import SwiftUI

struct SideView: View {
    @ObservedObject var calculator: LensCalculator
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color(.systemBackground)
                
                // 座標軸
                drawAxes(in: geometry)
                
                // 撮影位置（カメラ）
                drawCamera(in: geometry)
                
                // 花火の位置と範囲
                drawFireworks(in: geometry)
                
                // 画角範囲（視野角）
                drawFieldOfView(in: geometry)
                
                // 距離線
                drawDistanceLine(in: geometry)
                
                // ラベル
                drawLabels(in: geometry)
            }
        }
    }
    
    // MARK: - Draw Axes
    private func drawAxes(in geometry: GeometryProxy) -> some View {
        Group {
            // X軸（距離軸）- 地面
            Path { path in
                let margin: CGFloat = 40
                let groundY = geometry.size.height - margin
                path.move(to: CGPoint(x: margin, y: groundY))
                path.addLine(to: CGPoint(x: geometry.size.width - margin, y: groundY))
            }
            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            
            // Y軸（高さ軸）- 左側
            Path { path in
                let margin: CGFloat = 40
                let groundY = geometry.size.height - margin
                path.move(to: CGPoint(x: margin, y: margin))
                path.addLine(to: CGPoint(x: margin, y: groundY))
            }
            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
        }
    }
    
    // MARK: - Draw Camera
    private func drawCamera(in geometry: GeometryProxy) -> some View {
        let margin: CGFloat = 40
        let groundY = geometry.size.height - margin
        let cameraX = margin + 20
        let cameraY = groundY
        
        return Group {
            // カメラアイコン
            Circle()
                .fill(Color.blue)
                .frame(width: 16, height: 16)
                .position(x: cameraX, y: cameraY)
            
            // カメララベル
            Text("カメラ")
                .font(.caption2)
                .foregroundColor(.blue)
                .position(x: cameraX, y: cameraY + 15)
        }
    }
    
    // MARK: - Draw Fireworks
    private func drawFireworks(in geometry: GeometryProxy) -> some View {
        let margin: CGFloat = 40
        let groundY = geometry.size.height - margin
        let cameraX = margin + 20
        
        // 距離を画面の幅にマッピング
        let maxDistance: Double = max(calculator.distance * 1.5, 1000) // 表示範囲を距離の1.5倍に
        let distanceScale = (Double(geometry.size.width - margin * 2 - 40) - 20) / maxDistance
        
        let fireworksX = cameraX + CGFloat(calculator.distance * distanceScale)
        
        // 高さを画面の高さにマッピング
        let maxHeight = calculator.totalHeight * 1.2
        let heightScale = Double(groundY - margin) / maxHeight
        
        let launchHeight = calculator.fireworksCenterHeight
        let spreadRadius = calculator.fireworksDiameter / 2
        
        let fireworksTop = launchHeight + spreadRadius
        let fireworksBottom = max(0, launchHeight - spreadRadius)
        
        let topY = groundY - CGFloat(fireworksTop * heightScale)
        let bottomY = groundY - CGFloat(fireworksBottom * heightScale)
        let centerY = groundY - CGFloat(launchHeight * heightScale)
        
        return Group {
            // 花火の範囲（縦線）
            Path { path in
                path.move(to: CGPoint(x: fireworksX, y: topY))
                path.addLine(to: CGPoint(x: fireworksX, y: bottomY))
            }
            .stroke(Color.red, lineWidth: 3)
            
            // 花火の中心位置マーカー
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .position(x: fireworksX, y: centerY)
            
            // 花火の上端マーカー
            Circle()
                .fill(Color.orange)
                .frame(width: 8, height: 8)
                .position(x: fireworksX, y: topY)
            
            // 花火の下端マーカー
            Circle()
                .fill(Color.orange)
                .frame(width: 8, height: 8)
                .position(x: fireworksX, y: bottomY)
            
            // 花火の範囲表示（横線）
            Path { path in
                path.move(to: CGPoint(x: fireworksX - 15, y: topY))
                path.addLine(to: CGPoint(x: fireworksX + 15, y: topY))
                path.move(to: CGPoint(x: fireworksX - 15, y: bottomY))
                path.addLine(to: CGPoint(x: fireworksX + 15, y: bottomY))
            }
            .stroke(Color.red.opacity(0.5), lineWidth: 2)
        }
    }
    
    // MARK: - Draw Field of View
    private func drawFieldOfView(in geometry: GeometryProxy) -> some View {
        let margin: CGFloat = 40
        let groundY = geometry.size.height - margin
        let cameraX = margin + 20
        
        // 距離を画面の幅にマッピング
        let maxDistance: Double = max(calculator.distance * 1.5, 1000)
        let distanceScale = (Double(geometry.size.width - margin * 2 - 40) - 20) / maxDistance
        
        // 高さを画面の高さにマッピング
        let maxHeight = calculator.totalHeight * 1.2
        let heightScale = Double(groundY - margin) / maxHeight
        
        // 画角を計算（垂直方向）
        let sensor = calculator.sensorSize
        let lensMm = Double(calculator.recommendedLensMm)
        
        // 花火の高さを収めるために必要な画角（計算ロジックと同じ）
        let fireworksHeight = calculator.fireworksHeight
        let skyRatio = calculator.skyRatio
        let verticalAngleForFireworksRad = 2 * atan(fireworksHeight / (2 * calculator.distance))
        let effectiveVerticalAngleRad = verticalAngleForFireworksRad / skyRatio
        
        // 画角の上端と下端の角度（カメラの水平線からの角度）
        let topAngle = effectiveVerticalAngleRad / 2
        let bottomAngle = -effectiveVerticalAngleRad / 2
        
        // 花火までの距離での画角の範囲を計算
        let viewDistance = calculator.distance * distanceScale
        
        // 画角の範囲を線で描画
        return Group {
            // 上端の線
            Path { path in
                path.move(to: CGPoint(x: cameraX, y: groundY))
                let endX = cameraX + CGFloat(viewDistance)
                let endY = groundY - CGFloat(tan(topAngle) * Double(viewDistance))
                path.addLine(to: CGPoint(x: endX, y: endY))
            }
            .stroke(Color.blue.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
            
            // 下端の線
            Path { path in
                path.move(to: CGPoint(x: cameraX, y: groundY))
                let endX = cameraX + CGFloat(viewDistance)
                let endY = groundY - CGFloat(tan(bottomAngle) * Double(viewDistance))
                path.addLine(to: CGPoint(x: endX, y: endY))
            }
            .stroke(Color.blue.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
            
            // 画角の範囲を塗りつぶし（空の部分のみ）
            Path { path in
                path.move(to: CGPoint(x: cameraX, y: groundY))
                let topEndX = cameraX + CGFloat(viewDistance)
                let topEndY = groundY - CGFloat(tan(topAngle) * Double(viewDistance))
                path.addLine(to: CGPoint(x: topEndX, y: topEndY))
                let bottomEndX = cameraX + CGFloat(viewDistance)
                let bottomEndY = groundY - CGFloat(tan(bottomAngle) * Double(viewDistance))
                path.addLine(to: CGPoint(x: bottomEndX, y: bottomEndY))
                path.closeSubpath()
            }
            .fill(Color.blue.opacity(0.1))
        }
    }
    
    // MARK: - Draw Distance Line
    private func drawDistanceLine(in geometry: GeometryProxy) -> some View {
        let margin: CGFloat = 40
        let groundY = geometry.size.height - margin
        let cameraX = margin + 20
        
        let maxDistance: Double = max(calculator.distance * 1.5, 1000)
        let distanceScale = (Double(geometry.size.width - margin * 2 - 40) - 20) / maxDistance
        
        let fireworksX = cameraX + CGFloat(calculator.distance * distanceScale)
        
        return Group {
            // 距離線
            Path { path in
                path.move(to: CGPoint(x: cameraX, y: groundY))
                path.addLine(to: CGPoint(x: fireworksX, y: groundY))
            }
            .stroke(Color.green.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            
            // 距離ラベル
            Text("\(Int(calculator.distance))m")
                .font(.caption2)
                .foregroundColor(.green)
                .padding(4)
                .background(Color.white.opacity(0.8))
                .cornerRadius(4)
                .position(x: (cameraX + fireworksX) / 2, y: groundY + 10)
        }
    }
    
    // MARK: - Draw Labels
    private func drawLabels(in geometry: GeometryProxy) -> some View {
        let margin: CGFloat = 40
        let groundY = geometry.size.height - margin
        
        // 高さの目盛り
        let maxHeight = calculator.totalHeight * 1.2
        let heightScale = Double(groundY - margin) / maxHeight
        
        return VStack(alignment: .leading, spacing: 4) {
            // Y軸ラベル（高さ）
            Text("高さ (m)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .rotationEffect(.degrees(-90))
                .position(x: 15, y: (groundY + margin) / 2)
            
            // X軸ラベル（距離）
            Text("距離 (m)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .position(x: (geometry.size.width + margin) / 2, y: groundY + 25)
            
            // 高さの目盛り
            ForEach([0, 100, 200, 300, 400, 500, 600, 700], id: \.self) { height in
                if Double(height) <= maxHeight {
                    let y = groundY - CGFloat(Double(height) * heightScale)
                    Text("\(height)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .position(x: margin - 15, y: y)
                    
                    // 目盛り線
                    Path { path in
                        path.move(to: CGPoint(x: margin - 5, y: y))
                        path.addLine(to: CGPoint(x: margin + 5, y: y))
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }
            }
            
            // 距離の目盛り
            Group {
                let maxDistance: Double = max(calculator.distance * 1.5, 1000)
                let distanceScale = (Double(geometry.size.width - margin * 2 - 40) - 20) / maxDistance
                let cameraX = margin + 20
                
                ForEach([0, 200, 400, 600, 800, 1000], id: \.self) { dist in
                    if Double(dist) <= maxDistance {
                        let x = cameraX + CGFloat(Double(dist) * distanceScale)
                        if x < geometry.size.width - margin {
                            Text("\(dist)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .position(x: x, y: groundY + 15)
                            
                            // 目盛り線
                            Path { path in
                                path.move(to: CGPoint(x: x, y: groundY - 5))
                                path.addLine(to: CGPoint(x: x, y: groundY + 5))
                            }
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SideView(calculator: LensCalculator())
        .frame(height: 300)
}
