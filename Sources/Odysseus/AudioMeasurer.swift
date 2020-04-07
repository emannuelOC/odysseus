//
//  AudioMeasurer.swift
//  Lana
//
//  Created by Emannuel Carvalho on 04/04/20.
//  Copyright © 2020 Emannuel Carvalho. All rights reserved.
//

import Accelerate
import Foundation
import AVFoundation

class AudioMeasurer {
    
    /// Based on Farhad Malekpour's answer on stack overflow: https://stackoverflow.com/a/33166208/2557380
    /// and also on Shebin Koshy's adaptation to Swift https://stackoverflow.com/a/49796486/2557380
    
    private var averagePowerForChannel0 = Float(0)
    private var averagePowerForChannel1 = Float(0)
    let LEVEL_LOWPASS_TRIG = Float32(0.30)
    
    func level(for buffer: AVAudioPCMBuffer) -> Double {
        buffer.frameLength = 1024
        let inNumberFrames = UInt(buffer.frameLength)
        if buffer.format.channelCount > 0 {
            let samples = (buffer.floatChannelData![0])
            var avgValue = Float32(0)
            vDSP_meamgv(samples,1 , &avgValue, inNumberFrames)
            var v = Float(-100)
            if avgValue != 0 {
                v = 20.0 * log10f(avgValue)
            }
            self.averagePowerForChannel0 = (self.LEVEL_LOWPASS_TRIG * v) + ((1 - self.LEVEL_LOWPASS_TRIG) * self.averagePowerForChannel0)
            self.averagePowerForChannel1 = self.averagePowerForChannel0
        }
        
        if buffer.format.channelCount > 1 {
            let samples = buffer.floatChannelData![1]
            var avgValue:Float32 = 0
            vDSP_meamgv(samples, 1, &avgValue, inNumberFrames)
            var v:Float = -100
            if avgValue != 0 {
                v = 20.0 * log10f(avgValue)
            }
            self.averagePowerForChannel1 = (self.LEVEL_LOWPASS_TRIG * v) + ((1 - self.LEVEL_LOWPASS_TRIG) * self.averagePowerForChannel1)
        }
        return Double(self.averagePowerForChannel1) * -1.0
    }
}
