//
//  BasicVideoCall.swift
//  WebRTC Example
//
//  A complete example of a basic WebRTC video call implementation
//

import Foundation
import WebRTC
import AVFoundation

/// Basic WebRTC video call implementation
class BasicVideoCall: NSObject {
    
    // MARK: - Properties
    
    private var peerConnectionFactory: RTCPeerConnectionFactory!
    private var peerConnection: RTCPeerConnection?
    private var localVideoSource: RTCVideoSource?
    private var localVideoTrack: RTCVideoTrack?
    private var localAudioTrack: RTCAudioTrack?
    private var videoCapturer: RTCCameraVideoCapturer?
    private var remoteVideoTrack: RTCVideoTrack?
    
    // Callbacks
    var onLocalSDP: ((RTCSessionDescription) -> Void)?
    var onIceCandidate: ((RTCIceCandidate) -> Void)?
    var onRemoteVideoTrack: ((RTCVideoTrack) -> Void)?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupPeerConnectionFactory()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Setup
    
    private func setupPeerConnectionFactory() {
        RTCInitializeSSL()
        
        // Configure video encoder/decoder for H265
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        
        // Create factory
        peerConnectionFactory = RTCPeerConnectionFactory(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory
        )
    }
    
    // MARK: - Public Methods
    
    /// Start a video call
    func startCall(isInitiator: Bool) {
        setupLocalMedia()
        createPeerConnection()
        
        if isInitiator {
            createOffer()
        }
    }
    
    /// End the call
    func endCall() {
        peerConnection?.close()
        peerConnection = nil
        cleanup()
    }
    
    /// Handle remote SDP
    func handleRemoteSDP(_ sdp: RTCSessionDescription) {
        guard let pc = peerConnection else { return }
        
        pc.setRemoteDescription(sdp) { [weak self] error in
            if let error = error {
                print("Failed to set remote description: \(error)")
                return
            }
            
            // Create answer if we received an offer
            if sdp.type == .offer {
                self?.createAnswer()
            }
        }
    }
    
    /// Handle remote ICE candidate
    func handleRemoteCandidate(_ candidate: RTCIceCandidate) {
        peerConnection?.add(candidate)
    }
    
    // MARK: - Private Methods
    
    private func setupLocalMedia() {
        // Setup audio
        setupAudio()
        
        // Setup video
        setupVideo()
    }
    
    private func setupAudio() {
        // Configure audio session
        let audioSession = RTCAudioSession.sharedInstance()
        audioSession.lockForConfiguration()
        defer { audioSession.unlockForConfiguration() }
        
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
            try audioSession.setMode(AVAudioSession.Mode.voiceChat.rawValue)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        
        // Create audio track
        let audioSource = peerConnectionFactory.audioSource(with: nil)
        localAudioTrack = peerConnectionFactory.audioTrack(with: audioSource, trackId: "audio0")
    }
    
    private func setupVideo() {
        // Create video source
        localVideoSource = peerConnectionFactory.videoSource()
        
        // Create video track
        localVideoTrack = peerConnectionFactory.videoTrack(
            with: localVideoSource!,
            trackId: "video0"
        )
        
        // Setup camera capturer
        videoCapturer = RTCCameraVideoCapturer(delegate: localVideoSource!)
        startCameraCapture()
    }
    
    private func startCameraCapture() {
        guard let capturer = videoCapturer else { return }
        
        // Find front camera
        let devices = RTCCameraVideoCapturer.captureDevices()
        guard let device = devices.first(where: { $0.position == .front }) else {
            print("No front camera found")
            return
        }
        
        // Find suitable format (prefer 1280x720)
        let formats = RTCCameraVideoCapturer.supportedFormats(for: device)
        let targetWidth = 1280
        let targetHeight = 720
        
        var selectedFormat: AVCaptureDevice.Format?
        var currentDiff = Int.max
        
        for format in formats {
            let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let diff = abs(targetWidth - Int(dimension.width)) + 
                      abs(targetHeight - Int(dimension.height))
            if diff < currentDiff {
                selectedFormat = format
                currentDiff = diff
            }
        }
        
        guard let format = selectedFormat else { return }
        
        // Start capture at 30fps
        capturer.startCapture(with: device, format: format, fps: 30)
    }
    
    private func createPeerConnection() {
        // Configure
        let config = RTCConfiguration()
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        ]
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        
        // Set H265 as preferred codec
        config.encodedInsertableStreams = false
        
        // Create constraints
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": "true"]
        )
        
        // Create peer connection
        peerConnection = peerConnectionFactory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        )
        
        // Add local tracks
        if let localVideoTrack = localVideoTrack {
            peerConnection?.add(localVideoTrack, streamIds: ["stream0"])
        }
        
        if let localAudioTrack = localAudioTrack {
            peerConnection?.add(localAudioTrack, streamIds: ["stream0"])
        }
        
        // Configure H265 preference
        configureH265Preference()
    }
    
    private func configureH265Preference() {
        guard let pc = peerConnection else { return }
        
        // Get transceivers
        let transceivers = pc.transceivers
        
        for transceiver in transceivers {
            if transceiver.mediaType == .video {
                // Get available codecs
                var codecs = transceiver.sender.parameters.encodings
                let videoCodecs = RTCDefaultVideoEncoderFactory.supportedCodecs()
                
                // Find H265 codec
                if let h265Codec = videoCodecs.first(where: { $0.name == kRTCVideoCodecH265Name }) {
                    // Set H265 as preferred
                    transceiver.setCodecPreferences([h265Codec])
                }
            }
        }
    }
    
    private func createOffer() {
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "true",
                "OfferToReceiveVideo": "true"
            ],
            optionalConstraints: nil
        )
        
        peerConnection?.offer(for: constraints) { [weak self] sdp, error in
            guard let self = self, let sdp = sdp else {
                print("Failed to create offer: \(error?.localizedDescription ?? "")")
                return
            }
            
            self.peerConnection?.setLocalDescription(sdp) { error in
                if let error = error {
                    print("Failed to set local description: \(error)")
                    return
                }
                
                self.onLocalSDP?(sdp)
            }
        }
    }
    
    private func createAnswer() {
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "true",
                "OfferToReceiveVideo": "true"
            ],
            optionalConstraints: nil
        )
        
        peerConnection?.answer(for: constraints) { [weak self] sdp, error in
            guard let self = self, let sdp = sdp else {
                print("Failed to create answer: \(error?.localizedDescription ?? "")")
                return
            }
            
            self.peerConnection?.setLocalDescription(sdp) { error in
                if let error = error {
                    print("Failed to set local description: \(error)")
                    return
                }
                
                self.onLocalSDP?(sdp)
            }
        }
    }
    
    private func cleanup() {
        videoCapturer?.stopCapture()
        videoCapturer = nil
        localVideoTrack = nil
        localAudioTrack = nil
        localVideoSource = nil
        RTCCleanupSSL()
    }
}

// MARK: - RTCPeerConnectionDelegate

extension BasicVideoCall: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("Signaling state changed: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("Stream added (deprecated)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("Stream removed (deprecated)")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("Negotiation needed")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("ICE connection state: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("ICE gathering state: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        onIceCandidate?(candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("ICE candidates removed")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("Data channel opened")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange connectionState: RTCPeerConnectionState) {
        print("Connection state: \(connectionState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didStartReceivingOn transceiver: RTCRtpTransceiver) {
        print("Started receiving on transceiver")
        
        if transceiver.mediaType == .video,
           let track = transceiver.receiver.track as? RTCVideoTrack {
            remoteVideoTrack = track
            onRemoteVideoTrack?(track)
        }
    }
}

// MARK: - Helper Extensions

extension RTCIceConnectionState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .new: return "new"
        case .checking: return "checking"
        case .connected: return "connected"
        case .completed: return "completed"
        case .failed: return "failed"
        case .disconnected: return "disconnected"
        case .closed: return "closed"
        case .count: return "count"
        @unknown default: return "unknown"
        }
    }
}

extension RTCSignalingState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .stable: return "stable"
        case .haveLocalOffer: return "haveLocalOffer"
        case .haveLocalPrAnswer: return "haveLocalPrAnswer"
        case .haveRemoteOffer: return "haveRemoteOffer"
        case .haveRemotePrAnswer: return "haveRemotePrAnswer"
        case .closed: return "closed"
        @unknown default: return "unknown"
        }
    }
}

extension RTCPeerConnectionState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .new: return "new"
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .disconnected: return "disconnected"
        case .failed: return "failed"
        case .closed: return "closed"
        @unknown default: return "unknown"
        }
    }
}