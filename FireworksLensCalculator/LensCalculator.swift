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
    let diameter: Double  // 直径（m）
    let height: Double    // 高さ（m）
    
    init(number: Int, name: String, diameter: Double, height: Double) {
        self.id = number
        self.number = number
        self.name = name
        self.diameter = diameter
        self.height = height
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
    
    @Published var selectedFireworksSize: FireworksSize = FireworksSize.fireworksSizes[2] { // デフォルト: 10号玉
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
    
    // 花火の号数データ
    static let fireworksSizes: [FireworksSize] = [
        FireworksSize(number: 3, name: "3号", diameter: 60, height: 120),
        FireworksSize(number: 6, name: "6号", diameter: 180, height: 220),
        FireworksSize(number: 10, name: "10号", diameter: 280, height: 330),
        FireworksSize(number: 30, name: "30号", diameter: 600, height: 550),
        FireworksSize(number: 40, name: "40号", diameter: 700, height: 700)
    ]
    
    init() {
        calculate()
    }
    
    // MARK: - Calculation
    private func calculate() {
        // 花火のサイズ情報を取得
        // 花火の高さは開いた時の高さ（地上から上端まで）
        let fireworksHeight = selectedFireworksSize.height
        
        // 地上の割合から、空の割合を計算
        let skyRatio = (100 - groundRatio) / 100
        
        // 花火全体が画面に収まるようにするため、花火の高さを画面の空部分に収める
        // 花火の高さを画面に収めるために必要な画角
        // 画角 = 2 * arctan(被写体の高さ / (2 * 距離))
        let verticalAngleForFireworksRad = 2 * atan(fireworksHeight / (2 * distance))
        
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
        selectedFireworksSize.diameter
    }
    
    var fireworksHeight: Double {
        selectedFireworksSize.height
    }
    
    var fireworksTop: Double {
        selectedFireworksSize.height  // 花火の上端（地上から）
    }
    
    var fireworksBottom: Double {
        0  // 花火の下端は地上
    }
    
    var totalHeight: Double {
        fireworksTop  // 地上から花火の上端までの高さ
    }
    
    var skyRatio: Double {
        (100 - groundRatio) / 100
    }
    
    var spreadMeters: Double {
        fireworksHeight  // 花火の高さが広がりに相当
    }
    
    // 花火の中心位置（高さの半分）
    var fireworksCenterHeight: Double {
        fireworksHeight / 2
    }
}
