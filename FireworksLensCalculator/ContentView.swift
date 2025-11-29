//
//  ContentView.swift
//  FireworksLensCalculator
//
//  Created on 2024
//

import SwiftUI

struct ContentView: View {
    @StateObject private var calculator = LensCalculator()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 入力セクション
                    inputSection
                    
                    // 結果セクション
                    resultSection
                    
                    // プレビューセクション（正面図）
                    previewSection
                    
                    // 側面図セクション
                    sideViewSection
                }
                .padding()
            }
            .navigationTitle("🎆 花火撮影レンズ計算")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Input Section
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("撮影設定")
                .font(.title2)
                .fontWeight(.bold)
            
            // 撮影距離
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("撮影地から花火までの距離")
                    Spacer()
                    Text("\(Int(calculator.distance))m")
                        .foregroundColor(.secondary)
                }
                Slider(value: $calculator.distance, in: 50...5000, step: 10)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // 地上の割合
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("地上の割合")
                    Spacer()
                    Text("\(Int(calculator.groundRatio))%")
                        .foregroundColor(.secondary)
                }
                Slider(value: $calculator.groundRatio, in: 0...100, step: 5)
                Text("画面に占める地上部分の割合")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // 花火の号数選択
            VStack(alignment: .leading, spacing: 8) {
                Text("花火の号数")
                    .font(.headline)
                
                Picker("花火の号数", selection: $calculator.selectedFireworksSize) {
                    ForEach(LensCalculator.fireworksSizes) { size in
                        Text(size.name).tag(size)
                    }
                }
                .pickerStyle(.menu)
                
                HStack {
                    Text("打ち上げ高さ: \(Int(calculator.selectedFireworksSize.launchHeight))m")
                    Spacer()
                    Text("開いた直径: \(Int(calculator.fireworksDiameter))m")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // センサーサイズ選択
            VStack(alignment: .leading, spacing: 8) {
                Text("センサーサイズ")
                    .font(.headline)
                
                Picker("センサーサイズ", selection: $calculator.sensorSize) {
                    ForEach(LensCalculator.SensorSize.allCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Result Section
    private var resultSection: some View {
        VStack(spacing: 16) {
            Text("推奨レンズmm数")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(calculator.recommendedLensMm)")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(.blue)
                Text("mm")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            
            VStack(spacing: 8) {
                Text("画角: 約\(String(format: "%.1f", calculator.angleOfView))度（対角線）")
                Text("空の割合: \(Int(100 - calculator.groundRatio))% / 地上の割合: \(Int(calculator.groundRatio))%")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("構図プレビュー")
                .font(.title2)
                .fontWeight(.bold)
            
            PreviewView(calculator: calculator)
                .frame(height: 400)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 1)
                )
            
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("距離: \(Int(calculator.distance))m")
                    Text("花火: \(calculator.selectedFireworksSize.name)")
                    Text("地上割合: \(Int(calculator.groundRatio))%")
                    Text("レンズ: \(calculator.recommendedLensMm)mm")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Side View Section
    private var sideViewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("側面図（横から見たイメージ）")
                .font(.title2)
                .fontWeight(.bold)
            
            SideView(calculator: calculator)
                .frame(height: 400)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 1)
                )
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• 青い線: カメラの画角範囲")
                    Text("• 赤い線: 花火の高さ範囲")
                    Text("• 緑の線: 撮影距離")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

#Preview {
    ContentView()
}
