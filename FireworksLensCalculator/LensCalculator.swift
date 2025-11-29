//
//  LensCalculator.swift
//  FireworksLensCalculator
//
//  Created on 2024
//

import Foundation
import Combine

class LensCalculator: ObservableObject {
    // MARK: - Input Properties
    @Published var distance: Double = 500 {
        didSet { calculate() }
    }
    
    @Published var groundRatio: Double = 30 {
        didSet { calculate() }
    }
    
    @Published var launchHeight: Double = 300 {
        didSet { calculate() }
    }
    
    @Published var spreadShaku: Double = 2.0 {
        didSet { calculate() }
    }
    
    // MARK: - Output Properties
    @Published var recommendedLensMm: Int = 0
    @Published var angleOfView: Double = 0
    
    // MARK: - Constants
    // iPhoneのセンサーサイズ（1/2.55インチ、約6.17×4.55mm）
    // 35mm換算の焦点距離を計算するためのセンサーサイズ
    private let iphoneSensorWidth: Double = 6.17  // mm
    private let iphoneSensorHeight: Double = 4.55  // mm
    private let iphoneSensorDiagonal: Double = 7.66  // mm
    
    // 35mmフルサイズセンサー
    private let fullFrameWidth: Double = 36.0
    private let fullFrameHeight: Double = 24.0
    private let fullFrameDiagonal: Double = 43.27
    
    // 尺からメートルへの変換（1尺 ≈ 3.03m）
    private let shakuToMeter: Double = 3.03
    
    init() {
        calculate()
    }
    
    // MARK: - Calculation
    private func calculate() {
        // 花火の広がりをメートルに変換
        let spreadMeters = spreadShaku * shakuToMeter
        
        // 花火の実際の高さ範囲を計算
        // 打ち上げ高さを中心として、上下に広がり/2ずつ広がる
        let fireworksTop = launchHeight + spreadMeters / 2
        var fireworksBottom = launchHeight - spreadMeters / 2
        
        // 花火の下端が地上より下にならないように制限
        fireworksBottom = max(0, fireworksBottom)
        
        // 花火の実際の高さ（上端から下端まで）
        let fireworksHeight = fireworksTop - fireworksBottom
        
        // 地上の割合から、空の割合を計算
        let skyRatio = (100 - groundRatio) / 100
        
        // 花火全体が画面に収まるようにするため、花火の上端から下端までの範囲を
        // 画面の空部分に収める必要がある
        // 花火の上端が画面の空部分の上端に来るようにする
        // つまり、花火の上端までの高さを基準に画角を計算し、
        // その画角で花火全体（上端から下端まで）が空の部分に収まるようにする
        
        // 花火の上端までの高さから必要な画角を計算
        // 画角 = 2 * arctan(被写体の高さ / (2 * 距離))
        let verticalAngleForTopRad = 2 * atan(fireworksTop / (2 * distance))
        
        // この画角で花火全体が空の部分に収まるようにする
        // 空の部分の高さ = 画面の高さ × skyRatio
        // 花火の高さが空の部分の高さに収まる必要がある
        // つまり、effectiveVerticalAngleRadで花火の高さが収まるようにする
        
        // 花火の高さを画面に収めるために必要な画角
        let verticalAngleForFireworksRad = 2 * atan(fireworksHeight / (2 * distance))
        
        // 空の部分に収めるために、画角を調整
        // 空の部分の割合で割ることで、より広い画角が必要になる
        let effectiveVerticalAngleRad = verticalAngleForFireworksRad / skyRatio
        
        // iPhoneのセンサーサイズと画角からレンズmm数を計算
        // mm = (センサー高さ / 2) / tan(画角 / 2)
        let lensMmForiPhone = (iphoneSensorHeight / 2) / tan(effectiveVerticalAngleRad / 2)
        
        // 35mm換算の焦点距離に変換
        // 35mm換算 = iPhoneの焦点距離 × (35mmセンサー対角線 / iPhoneセンサー対角線)
        let lensMm35mm = lensMmForiPhone * (fullFrameDiagonal / iphoneSensorDiagonal)
        
        recommendedLensMm = Int(round(lensMm35mm))
        
        // 画角の計算（35mm換算）
        let angleRad = 2 * atan(fullFrameDiagonal / (2 * lensMm35mm))
        angleOfView = angleRad * (180 / .pi)
    }
    
    // MARK: - Helper Properties
    var spreadMeters: Double {
        spreadShaku * shakuToMeter
    }
    
    var fireworksTop: Double {
        launchHeight + spreadMeters / 2
    }
    
    var fireworksBottom: Double {
        max(0, launchHeight - spreadMeters / 2)
    }
    
    var totalHeight: Double {
        fireworksTop
    }
    
    var skyRatio: Double {
        (100 - groundRatio) / 100
    }
}
