//
//  LensCalculator.swift
//  FireworksLensCalculator
//
//  Created on 2024
//

import Foundation
import Combine

// 花火の号数データ構造
struct FireworksSize: Identifiable, Equatable {
    let id: Int
    let number: Int
    let name: String
    let launchHeight: Double      // 上がる高さ（m）
    let spreadDiameter: Double     // 開いたときの直径（m）
    
    init(number: Int, name: String, launchHeight: Double, spreadDiameter: Double) {
        self.id = number
        self.number = number
        self.name = name
        self.launchHeight = launchHeight
        self.spreadDiameter = spreadDiameter
    }
}

class LensCalculator: ObservableObject {
    // MARK: - Input Properties
    @Published var distance: Double = 500 {
        didSet { calculate() }
    }
    
    @Published var groundRatio: Double = 30 {
        didSet { calculate() }
    }
    
    @Published var selectedFireworksSize: FireworksSize = FireworksSize.fireworksSizes[6] { // デフォルト: 10号玉
        didSet { calculate() }
    }
    
    @Published var sensorSize: SensorSize = .fullFrame {
        didSet { calculate() }
    }
    
    // MARK: - Output Properties
    @Published var recommendedLensMm: Int = 0
    @Published var angleOfView: Double = 0
    
    // MARK: - Constants
    // センサーサイズの定義
    enum SensorSize: String, CaseIterable {
        case fullFrame = "full"
        case apsc = "apsc"
        case microFourThirds = "m43"
        
        var displayName: String {
            switch self {
            case .fullFrame: return "フルサイズ (36×24mm)"
            case .apsc: return "APS-C (23.6×15.7mm)"
            case .microFourThirds: return "マイクロフォーサーズ (17.3×13mm)"
            }
        }
        
        var width: Double {
            switch self {
            case .fullFrame: return 36.0
            case .apsc: return 23.6
            case .microFourThirds: return 17.3
            }
        }
        
        var height: Double {
            switch self {
            case .fullFrame: return 24.0
            case .apsc: return 15.7
            case .microFourThirds: return 13.0
            }
        }
        
        var diagonal: Double {
            sqrt(width * width + height * height)
        }
    }
    
    // 花火の号数データ（打ち上げ花火の諸元に基づく）
    static let fireworksSizes: [FireworksSize] = [
        FireworksSize(number: 3, name: "3号", launchHeight: 120, spreadDiameter: 60),
        FireworksSize(number: 4, name: "4号", launchHeight: 160, spreadDiameter: 130),
        FireworksSize(number: 5, name: "5号", launchHeight: 190, spreadDiameter: 170),
        FireworksSize(number: 6, name: "6号", launchHeight: 220, spreadDiameter: 220),
        FireworksSize(number: 7, name: "7号", launchHeight: 250, spreadDiameter: 240),
        FireworksSize(number: 8, name: "8号", launchHeight: 280, spreadDiameter: 280),
        FireworksSize(number: 10, name: "10号", launchHeight: 330, spreadDiameter: 320),
        FireworksSize(number: 20, name: "20号", launchHeight: 500, spreadDiameter: 480),
        FireworksSize(number: 30, name: "30号", launchHeight: 600, spreadDiameter: 550)
    ]
    
    init() {
        calculate()
    }
    
    // MARK: - Calculation
    private func calculate() {
        // 花火のサイズ情報を取得
        let launchHeight = selectedFireworksSize.launchHeight      // 上がる高さ
        let spreadDiameter = selectedFireworksSize.spreadDiameter // 開いたときの直径
        
        // 花火の中心位置は打ち上げ高さ
        // 花火が開いた時の範囲：中心から上下に直径/2ずつ広がる
        let fireworksTop = launchHeight + spreadDiameter / 2
        let fireworksBottom = max(0, launchHeight - spreadDiameter / 2)  // 地上より下にならない
        
        // 花火の実際の高さ（上端から下端まで）
        let actualFireworksHeight = fireworksTop - fireworksBottom
        
        // 地上の割合から、空の割合を計算
        let skyRatio = (100 - groundRatio) / 100
        
        // 花火全体が画面に収まるようにするため、花火の高さを画面の空部分に収める
        // 花火の高さを画面に収めるために必要な画角
        // 画角 = 2 * arctan(被写体の高さ / (2 * 距離))
        let verticalAngleForFireworksRad = 2 * atan(actualFireworksHeight / (2 * distance))
        
        // 空の部分に収めるために、画角を調整
        // 空の部分の割合で割ることで、より広い画角が必要になる
        let effectiveVerticalAngleRad = verticalAngleForFireworksRad / skyRatio
        
        // 選択されたセンサーサイズと画角からレンズmm数を計算
        // mm = (センサー高さ / 2) / tan(画角 / 2)
        let sensor = sensorSize
        let lensMm = (sensor.height / 2) / tan(effectiveVerticalAngleRad / 2)
        
        recommendedLensMm = Int(round(lensMm))
        
        // 画角の計算（選択されたセンサーサイズ）
        let angleRad = 2 * atan(sensor.diagonal / (2 * lensMm))
        angleOfView = angleRad * (180 / .pi)
    }
    
    // MARK: - Helper Properties
    var fireworksDiameter: Double {
        selectedFireworksSize.spreadDiameter  // 開いたときの直径
    }
    
    var fireworksHeight: Double {
        let top = fireworksTop
        let bottom = fireworksBottom
        return top - bottom  // 花火の実際の高さ
    }
    
    var fireworksTop: Double {
        selectedFireworksSize.launchHeight + selectedFireworksSize.spreadDiameter / 2
    }
    
    var fireworksBottom: Double {
        max(0, selectedFireworksSize.launchHeight - selectedFireworksSize.spreadDiameter / 2)
    }
    
    var totalHeight: Double {
        fireworksTop  // 地上から花火の上端までの高さ
    }
    
    var skyRatio: Double {
        (100 - groundRatio) / 100
    }
    
    var spreadMeters: Double {
        selectedFireworksSize.spreadDiameter  // 開いたときの直径
    }
    
    // 花火の中心位置（打ち上げ高さ）
    var fireworksCenterHeight: Double {
        selectedFireworksSize.launchHeight
    }
}
