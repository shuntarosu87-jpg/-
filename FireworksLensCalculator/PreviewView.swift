//
//  PreviewView.swift
//  FireworksLensCalculator
//
//  Created on 2024
//

import SwiftUI

struct PreviewView: View {
    @ObservedObject var calculator: LensCalculator
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景（空と地面）
                VStack(spacing: 0) {
                    // 空
                    LinearGradient(
                        colors: [
                            Color(red: 0.1, green: 0.1, blue: 0.18),
                            Color(red: 0.09, green: 0.13, blue: 0.24),
                            Color(red: 0.06, green: 0.21, blue: 0.38)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * calculator.skyRatio)
                    
                    // 地面
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.31, blue: 0.09),
                            Color(red: 0.10, green: 0.19, blue: 0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * (1 - calculator.skyRatio))
                }
                
                // 地平線
                Path { path in
                    let y = geometry.size.height * calculator.skyRatio
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
                .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                
                // 三分割法のガイドライン
                gridLines(in: geometry)
                
                // 花火
                fireworks(in: geometry)
                
                // 距離線とラベル
                distanceLine(in: geometry)
                
                // 撮影位置マーカー
                cameraMarker(in: geometry)
            }
        }
    }
    
    // MARK: - Grid Lines
    private func gridLines(in geometry: GeometryProxy) -> some View {
        Group {
            // 垂直線
            Path { path in
                for i in 1..<3 {
                    let x = (geometry.size.width / 3) * CGFloat(i)
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
            }
            .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            
            // 水平線
            Path { path in
                for i in 1..<3 {
                    let y = (geometry.size.height / 3) * CGFloat(i)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
    }
    
    // MARK: - Fireworks
    private func fireworks(in geometry: GeometryProxy) -> some View {
        let skyHeight = geometry.size.height * calculator.skyRatio
        let centerX = geometry.size.width / 2
        
        // 距離に応じてスケール調整（近いほど大きく見える）
        let scale = min(1.0, 500.0 / calculator.distance)
        
        // 花火の中心位置（高さの半分の位置）
        // 空の部分の高さに対して、花火の中心位置を計算
        let totalHeight = calculator.totalHeight
        let fireworksCenterRatio = calculator.fireworksCenterHeight / totalHeight
        let fireworksCenterY = skyHeight * CGFloat(fireworksCenterRatio) * scale
        
        // 花火の半径（直径の半分を表示）
        // 花火の直径を画面の幅にマッピング（ただし、高さも考慮）
        let fireworksDiameterRatio = calculator.fireworksDiameter / totalHeight
        let fireworksRadius = skyHeight * CGFloat(fireworksDiameterRatio / 2) * scale
        
        return ZStack {
            // 花火の円（複数の円で表現）
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                fireworkColor(for: i).opacity(0.8 - Double(i) * 0.15),
                                fireworkColor(for: i).opacity(0.3 - Double(i) * 0.1)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: fireworksRadius * (0.3 + CGFloat(i) * 0.15)
                        )
                    )
                    .frame(width: fireworksRadius * (0.6 + CGFloat(i) * 0.3),
                           height: fireworksRadius * (0.6 + CGFloat(i) * 0.3))
                    .position(x: centerX, y: fireworksCenterY)
            }
            
            // 花火の光線
            ForEach(0..<8, id: \.self) { i in
                let angle = (Double.pi * 2 * Double(i)) / 8
                let startX = centerX + cos(angle) * fireworksRadius * 0.5
                let startY = fireworksCenterY + sin(angle) * fireworksRadius * 0.5
                let endX = centerX + cos(angle) * fireworksRadius * 1.5
                let endY = fireworksCenterY + sin(angle) * fireworksRadius * 1.5
                
                Path { path in
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
                .stroke(fireworkColor(for: i % 5), lineWidth: 2)
            }
        }
    }
    
    private func fireworkColor(for index: Int) -> Color {
        let colors: [Color] = [
            .red,
            .cyan,
            .yellow,
            .orange,
            .green
        ]
        return colors[index % colors.count]
    }
    
    // MARK: - Distance Line
    private func distanceLine(in geometry: GeometryProxy) -> some View {
        let skyHeight = geometry.size.height * calculator.skyRatio
        let cameraY = geometry.size.height - 20
        let centerX = geometry.size.width / 2
        
        // 花火の中心位置を計算（fireworks関数と同じロジック）
        let scale = min(1.0, 500.0 / calculator.distance)
        let fireworksCenterRatio = calculator.fireworksCenterHeight / calculator.totalHeight
        let fireworksCenterY = skyHeight * CGFloat(fireworksCenterRatio) * scale
        
        return Group {
            // 距離線
            Path { path in
                path.move(to: CGPoint(x: centerX, y: cameraY))
                path.addLine(to: CGPoint(x: centerX, y: fireworksCenterY))
            }
            .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
            
            // 距離ラベル
            Text("\(Int(calculator.distance))m")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .padding(4)
                .background(Color.black.opacity(0.3))
                .cornerRadius(4)
                .position(x: centerX, y: (cameraY + fireworksCenterY) / 2)
        }
    }
    
    // MARK: - Camera Marker
    private func cameraMarker(in geometry: GeometryProxy) -> some View {
        let centerX = geometry.size.width / 2
        let cameraY = geometry.size.height - 20
        
        return Circle()
            .fill(Color.white)
            .frame(width: 16, height: 16)
            .overlay(
                Circle()
                    .stroke(Color.black, lineWidth: 2)
            )
            .position(x: centerX, y: cameraY)
    }
}

#Preview {
    PreviewView(calculator: LensCalculator())
        .frame(height: 400)
}
