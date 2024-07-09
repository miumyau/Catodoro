import AudioToolbox
import AVFoundation
class SoundManager {
    var audioPlayer: AVAudioPlayer?
    
    func playSound(fileName: String, type: String, isRepeated: Bool) {
        guard let path = Bundle.main.path(forResource: fileName, ofType: type) else {
            print("ERROR: Sound file \(fileName).\(type) not found!")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            if isRepeated {
                audioPlayer?.numberOfLoops = -1
            }
            
            if isSoundEnabled {
                audioPlayer?.play()
            }
            
            if isVibrationEnabled {
                // Включаем вибрацию асинхронно
                vibrate(duration: audioPlayer?.duration ?? 0)
            }
            
        } catch {
            print("ERROR: Could not play the sound file \(fileName).\(type)")
        }
    }
    
    func stopSound() {
        audioPlayer?.stop()
    }
    
    private func vibrate(duration: TimeInterval) {
        // Используем главную очередь для вибрации, чтобы обновления UI происходили сразу
        DispatchQueue.main.async {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            DispatchQueue.global().asyncAfter(deadline: .now() + duration) {
                AudioServicesDisposeSystemSoundID(SystemSoundID(kSystemSoundID_Vibrate))
            }
        }
    }
}
