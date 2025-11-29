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
                    
                    // プレビューセクション
                    previewSection
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
            
            // 打ち上げ高さ
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("花火の打ち上げ高さ")
                    Spacer()
                    Text("\(Int(calculator.launchHeight))m")
                        .foregroundColor(.secondary)
                }
                Slider(value: $calculator.launchHeight, in: 50...1000, step: 10)
                Text("一般的な花火の高さは200-400m")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // 花火の広がり（尺）
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("花火が開いた時の広がり")
                    Spacer()
                    Text(String(format: "%.1f尺", calculator.spreadShaku))
                        .foregroundColor(.secondary)
                }
                Slider(value: $calculator.spreadShaku, in: 0...4, step: 0.1)
                Text("最大4尺まで（1尺 ≈ 3.03m）")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
}

#Preview {
    ContentView()
}
