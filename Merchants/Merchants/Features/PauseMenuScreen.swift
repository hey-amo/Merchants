//
//  PauseMenuScreen.swift
//  Merchants
//
//  Created by Amarjit on 02/07/2026.
//

import SwiftUI

private struct AudioSettings {
    var musicVolume = 1.0
    var soundVolume = 1.0
}

struct PauseMenuScreen: View {
    @State private var audioSettings = AudioSettings()
    var onContinue: () -> Void
    var onQuit: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black
                .opacity(0.4)
                .ignoresSafeArea()
            
            // Pause Menu Card
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Settings")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.systemGray6))
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Music Volume Settings
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                Text("Music Volume")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(Int(audioSettings.musicVolume * 100))%")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $audioSettings.musicVolume, in: 0...1, step: 0.01)
                                .tint(.blue)
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Sound Volume Settings
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                Text("Sound Effects")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(Int(audioSettings.soundVolume * 100))%")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $audioSettings.soundVolume, in: 0...1, step: 0.01)
                                .tint(.blue)
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(20)
                }
                
                Divider()
                
                // Buttons
                VStack(spacing: 12) {
                    // Continue Button
                    Button(action: onContinue) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text("Continue Game")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    // Quit Button
                    Button(action: onQuit) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text("Quit Game")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundColor(.white)
                        .background(Color(.systemRed))
                        .cornerRadius(12)
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: 360)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 12)
        }
    }
}

#Preview {
    PauseMenuScreen(
        onContinue: { print("Continue") },
        onQuit: { print("Quit") }
    )
}
