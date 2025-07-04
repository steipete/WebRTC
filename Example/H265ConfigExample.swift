//
//  H265ConfigExample.swift
//  WebRTC Example
//
//  Example of configuring WebRTC to use H265/HEVC codec
//

import Foundation
import WebRTC

/// Example showing how to configure and use H265/HEVC codec
class H265ConfigExample {
    
    private var peerConnectionFactory: RTCPeerConnectionFactory!
    private var peerConnection: RTCPeerConnection?
    
    // MARK: - H265 Configuration
    
    /// Create a peer connection factory with H265 support
    func createH265Factory() -> RTCPeerConnectionFactory {
        RTCInitializeSSL()
        
        // Create custom video encoder factory with H265 support
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        
        // Verify H265 is supported
        let supportedCodecs = RTCDefaultVideoEncoderFactory.supportedCodecs()
        let hasH265 = supportedCodecs.contains { $0.name == kRTCVideoCodecH265Name }
        print("H265 support: \(hasH265)")
        
        if hasH265 {
            print("Available H265 profiles:")
            for codec in supportedCodecs where codec.name == kRTCVideoCodecH265Name {
                print("  - \(codec.parameters)")
            }
        }
        
        return RTCPeerConnectionFactory(
            encoderFactory: encoderFactory,
            decoderFactory: decoderFactory
        )
    }
    
    /// Configure peer connection to prefer H265
    func configurePeerConnectionForH265() {
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        config.sdpSemantics = .unifiedPlan
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: nil
        )
        
        peerConnectionFactory = createH265Factory()
        peerConnection = peerConnectionFactory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: nil
        )
        
        // Add video transceiver with H265 preference
        addH265VideoTransceiver()
    }
    
    /// Add video transceiver with H265 codec preference
    private func addH265VideoTransceiver() {
        guard let pc = peerConnection else { return }
        
        // Create transceiver init
        let transceiverInit = RTCRtpTransceiverInit()
        transceiverInit.direction = .sendRecv
        
        // Add video transceiver
        let transceiver = pc.addTransceiver(of: .video, init: transceiverInit)
        
        // Get available codecs
        let factory = RTCDefaultVideoEncoderFactory()
        let availableCodecs = factory.supportedCodecs()
        
        // Build codec preference list with H265 first
        var preferredCodecs: [RTCVideoCodecInfo] = []
        
        // Add H265 first if available
        if let h265Codec = availableCodecs.first(where: { $0.name == kRTCVideoCodecH265Name }) {
            preferredCodecs.append(h265Codec)
            print("Added H265 as preferred codec")
        }
        
        // Add other codecs as fallback
        for codec in availableCodecs {
            if codec.name != kRTCVideoCodecH265Name {
                preferredCodecs.append(codec)
            }
        }
        
        // Set codec preferences
        transceiver?.setCodecPreferences(preferredCodecs)
        
        // Configure sender parameters for H265
        if let sender = transceiver?.sender {
            configureH265EncodingParameters(sender: sender)
        }
    }
    
    /// Configure encoding parameters optimized for H265
    private func configureH265EncodingParameters(sender: RTCRtpSender) {
        let parameters = sender.parameters
        
        // Configure encodings for H265
        for encoding in parameters.encodings {
            // H265 specific bitrate settings
            encoding.maxBitrateBps = NSNumber(value: 2_500_000) // 2.5 Mbps
            encoding.minBitrateBps = NSNumber(value: 500_000)   // 500 Kbps
            encoding.maxFramerate = NSNumber(value: 30)
            
            // Enable temporal scalability for H265
            encoding.numTemporalLayers = NSNumber(value: 3)
            
            // Set scale resolution factor
            encoding.scaleResolutionDownBy = NSNumber(value: 1.0)
            
            encoding.isActive = true
        }
        
        sender.parameters = parameters
    }
    
    // MARK: - SDP Manipulation for H265
    
    /// Modify SDP to prefer H265 codec
    func preferH265InSDP(_ sdp: RTCSessionDescription) -> RTCSessionDescription {
        var modifiedSDP = sdp.sdp
        
        // Find H265 payload type
        let h265Pattern = "a=rtpmap:(\\d+) H265/90000"
        guard let h265Regex = try? NSRegularExpression(pattern: h265Pattern),
              let match = h265Regex.firstMatch(
                in: modifiedSDP,
                range: NSRange(modifiedSDP.startIndex..., in: modifiedSDP)
              ),
              let payloadRange = Range(match.range(at: 1), in: modifiedSDP) else {
            print("H265 not found in SDP")
            return sdp
        }
        
        let h265PayloadType = String(modifiedSDP[payloadRange])
        
        // Modify m=video line to put H265 first
        let videoLinePattern = "m=video \\d+ [A-Z/]+ ([0-9 ]+)"
        if let videoRegex = try? NSRegularExpression(pattern: videoLinePattern),
           let videoMatch = videoRegex.firstMatch(
               in: modifiedSDP,
               range: NSRange(modifiedSDP.startIndex..., in: modifiedSDP)
           ),
           let codecsRange = Range(videoMatch.range(at: 1), in: modifiedSDP) {
            
            let codecs = modifiedSDP[codecsRange].split(separator: " ").map(String.init)
            var reorderedCodecs = [h265PayloadType]
            reorderedCodecs.append(contentsOf: codecs.filter { $0 != h265PayloadType })
            
            let newCodecString = reorderedCodecs.joined(separator: " ")
            modifiedSDP.replaceSubrange(codecsRange, with: newCodecString)
        }
        
        return RTCSessionDescription(type: sdp.type, sdp: modifiedSDP)
    }
    
    // MARK: - Bitrate Adaptation for H265
    
    /// Configure adaptive bitrate for H265
    func configureAdaptiveBitrate(for sender: RTCRtpSender, basedOn networkQuality: NetworkQuality) {
        let parameters = sender.parameters
        
        guard let encoding = parameters.encodings.first else { return }
        
        switch networkQuality {
        case .excellent:
            // High quality H265 settings
            encoding.maxBitrateBps = NSNumber(value: 4_000_000) // 4 Mbps
            encoding.scaleResolutionDownBy = NSNumber(value: 1.0)
            
        case .good:
            // Medium quality H265 settings
            encoding.maxBitrateBps = NSNumber(value: 2_000_000) // 2 Mbps
            encoding.scaleResolutionDownBy = NSNumber(value: 1.0)
            
        case .fair:
            // Lower quality but maintain resolution
            encoding.maxBitrateBps = NSNumber(value: 1_000_000) // 1 Mbps
            encoding.scaleResolutionDownBy = NSNumber(value: 1.5)
            
        case .poor:
            // Minimum quality H265 settings
            encoding.maxBitrateBps = NSNumber(value: 500_000) // 500 Kbps
            encoding.scaleResolutionDownBy = NSNumber(value: 2.0)
        }
        
        sender.parameters = parameters
    }
    
    // MARK: - Stats Collection
    
    /// Collect H265 specific statistics
    func collectH265Stats(completion: @escaping (H265Stats?) -> Void) {
        peerConnection?.statistics { [weak self] stats in
            var h265Stats: H265Stats?
            
            for stat in stats {
                // Check for outbound video stats
                if stat.type == "outbound-rtp",
                   let codecId = stat.values["codecId"] as? String {
                    
                    // Find the codec stats
                    if let codecStat = stats.first(where: { $0.id == codecId }),
                       let mimeType = codecStat.values["mimeType"] as? String,
                       mimeType.contains("H265") {
                        
                        h265Stats = H265Stats(
                            bytesSent: stat.values["bytesSent"] as? Int64 ?? 0,
                            packetsSent: stat.values["packetsSent"] as? Int ?? 0,
                            framesEncoded: stat.values["framesEncoded"] as? Int ?? 0,
                            keyFramesEncoded: stat.values["keyFramesEncoded"] as? Int ?? 0,
                            totalEncodeTime: stat.values["totalEncodeTime"] as? Double ?? 0,
                            qualityLimitationReason: stat.values["qualityLimitationReason"] as? String
                        )
                        break
                    }
                }
            }
            
            completion(h265Stats)
        }
    }
}

// MARK: - Supporting Types

enum NetworkQuality {
    case excellent
    case good
    case fair
    case poor
}

struct H265Stats {
    let bytesSent: Int64
    let packetsSent: Int
    let framesEncoded: Int
    let keyFramesEncoded: Int
    let totalEncodeTime: Double
    let qualityLimitationReason: String?
    
    var averageEncodeTime: Double {
        return framesEncoded > 0 ? totalEncodeTime / Double(framesEncoded) : 0
    }
    
    var bitrate: Int {
        // Calculate approximate bitrate (bytes * 8 / seconds)
        return Int(Double(bytesSent) * 8 / max(totalEncodeTime, 1))
    }
}

// MARK: - H265 Profile Configuration

extension H265ConfigExample {
    
    /// Configure specific H265 profile
    func configureH265Profile(_ profile: H265Profile, for sender: RTCRtpSender) {
        let parameters = sender.parameters
        
        guard let encoding = parameters.encodings.first else { return }
        
        switch profile {
        case .main:
            // Main profile - balanced quality and compatibility
            encoding.maxBitrateBps = NSNumber(value: 2_000_000)
            encoding.maxFramerate = NSNumber(value: 30)
            
        case .main10:
            // Main 10 profile - higher quality, 10-bit
            encoding.maxBitrateBps = NSNumber(value: 3_000_000)
            encoding.maxFramerate = NSNumber(value: 30)
            
        case .mainStillPicture:
            // For screen sharing or presentations
            encoding.maxBitrateBps = NSNumber(value: 1_500_000)
            encoding.maxFramerate = NSNumber(value: 10)
        }
        
        sender.parameters = parameters
    }
    
    enum H265Profile {
        case main
        case main10
        case mainStillPicture
    }
}