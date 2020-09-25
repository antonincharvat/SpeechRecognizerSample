//
//  Vocabulary.swift
//  SpeechRecognizerSample
//
//  Created by Antonín Charvát on 25/09/2020.
//  Copyright © 2020 AntoninCharvat. All rights reserved.
//

import Foundation

enum Vocabulary {
    case attention
    case slowDown
    case speedUp
    case nevermind
    case stop
        
    var phrases: [String] {
        switch self {
        case .attention:
            return ["hey buddy", "okay buddy", "ok buddy", "listen buddy"]
        case .slowDown:
            return ["slow down"]
        case .speedUp:
            return ["speed up"]
        case .nevermind:
            return ["nevermind", "never mind", "nothing"]
        case .stop:
            return ["stop"]
        }
    }
}
