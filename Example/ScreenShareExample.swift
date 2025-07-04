//
//  ScreenShareExample.swift
//  WebRTC Example
//
//  Example implementation of screen sharing using WebRTC
//

import Foundation
import WebRTC
import CoreGraphics
import AVFoundation

/// Screen sharing implementation using WebRTC
class ScreenShareExample: NSObject {
    
    // MARK: - Properties
    
    private var peerConnectionFactory: RTCPeerConnectionFactory!
    private var screenSource: RTCVideoSource?
    private var screenTrack: RTCVideoTrack?
    private var displayLink: CVDisplayLink?
    private var isCapturing = false
    
    // Capture settings
    private let targetFPS: Int = 30
    private let maxBitrate: Int = 4_000_000 // 4 Mbps for screen share
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupPeerConnectionFactory()
    }
    
    deinit {
        stopScreenShare()
    }
    
    // MARK: - Setup
    
    private func setupPeerConnectionFactory() {
        RTCInitializeSSL()
        
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        
        peerConnectionFactory = RTCPeerConnectionFactory(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory
        )
    }
    
    // MARK: - Public Methods
    
    /// Start screen sharing
    func startScreenShare() -> RTCVideoTrack? {
        guard !isCapturing else { return screenTrack }
        
        // Request screen recording permission
        requestScreenRecordingPermission()
        
        // Create video source for screen
        screenSource = peerConnectionFactory.videoSource()
        screenSource?.adaptOutputFormat(
            toWidth: 1920,
            height: 1080,
            fps: Int32(targetFPS)
        )
        
        // Create video track
        screenTrack = peerConnectionFactory.videoTrack(
            with: screenSource!,
            trackId: "screen0"
        )
        
        // Start capture
        startCapture()
        
        return screenTrack
    }
    
    /// Stop screen sharing
    func stopScreenShare() {
        isCapturing = false
        
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
            self.displayLink = nil
        }
        
        screenTrack = nil
        screenSource = nil
    }
    
    /// Configure screen share encoding parameters
    func configureScreenShareParameters(for sender: RTCRtpSender) {
        let parameters = sender.parameters
        
        // Configure encoding for screen share
        if let encoding = parameters.encodings.first {
            encoding.maxBitrateBps = NSNumber(value: maxBitrate)
            encoding.maxFramerate = NSNumber(value: targetFPS)
            encoding.scaleResolutionDownBy = NSNumber(value: 1.0)
            
            // Screen share specific settings
            encoding.networkPriority = .high
            encoding.isActive = true
        }
        
        sender.parameters = parameters
    }
    
    // MARK: - Private Methods
    
    private func requestScreenRecordingPermission() {
        if !CGPreflightScreenCaptureAccess() {
            CGRequestScreenCaptureAccess()
        }
    }
    
    private func startCapture() {
        // Create display link for capturing
        let displayID = CGMainDisplayID()
        
        CVDisplayLinkCreateWithCGDisplay(displayID, &displayLink)
        
        guard let displayLink = displayLink else {
            print("Failed to create display link")
            return
        }
        
        // Set callback
        CVDisplayLinkSetOutputCallback(displayLink, { (displayLink, inNow, inOutputTime, flagsIn, flagsOut, context) -> CVReturn in
            let screenShare = Unmanaged<ScreenShareExample>.fromOpaque(context!).takeUnretainedValue()
            screenShare.captureScreen()
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self).toOpaque())
        
        isCapturing = true
        CVDisplayLinkStart(displayLink)
    }
    
    private func captureScreen() {
        guard isCapturing else { return }
        
        autoreleasepool {
            // Capture main display
            let displayID = CGMainDisplayID()
            
            guard let image = CGDisplayCreateImage(displayID) else {
                return
            }
            
            // Convert CGImage to CVPixelBuffer
            if let pixelBuffer = convertToPixelBuffer(image: image) {
                // Create video frame
                let rotation = RTCVideoRotation._0
                let timeStampNs = Int64(CACurrentMediaTime() * 1_000_000_000)
                
                let rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
                let videoFrame = RTCVideoFrame(
                    buffer: rtcPixelBuffer,
                    rotation: rotation,
                    timeStampNs: timeStampNs
                )
                
                // Send frame to video source
                screenSource?.capturer(self as RTCVideoCapturer, didCapture: videoFrame)
            }
        }
    }
    
    private func convertToPixelBuffer(image: CGImage) -> CVPixelBuffer? {
        let width = image.width
        let height = image.height
        
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue!
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            attrs,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        defer {
            CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }
        
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return buffer
    }
}

// MARK: - Screen Share with Window Selection

extension ScreenShareExample {
    
    /// Get available windows for sharing
    func getAvailableWindows() -> [(windowID: CGWindowID, title: String, appName: String)] {
        var windows: [(CGWindowID, String, String)] = []
        
        let options = CGWindowListOption.optionOnScreenOnly
        let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
        
        for window in windowList {
            guard let windowID = window[kCGWindowNumber as String] as? CGWindowID,
                  let windowTitle = window[kCGWindowName as String] as? String,
                  let appName = window[kCGWindowOwnerName as String] as? String,
                  let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let width = bounds["Width"] as? CGFloat,
                  let height = bounds["Height"] as? CGFloat,
                  width > 100 && height > 100 else { // Filter out small windows
                continue
            }
            
            windows.append((windowID, windowTitle, appName))
        }
        
        return windows
    }
    
    /// Start sharing a specific window
    func startWindowShare(windowID: CGWindowID) -> RTCVideoTrack? {
        guard !isCapturing else { return screenTrack }
        
        requestScreenRecordingPermission()
        
        // Create video source
        screenSource = peerConnectionFactory.videoSource()
        
        // Create video track
        screenTrack = peerConnectionFactory.videoTrack(
            with: screenSource!,
            trackId: "window0"
        )
        
        // Start window capture
        startWindowCapture(windowID: windowID)
        
        return screenTrack
    }
    
    private func startWindowCapture(windowID: CGWindowID) {
        Timer.scheduledTimer(withTimeInterval: 1.0 / Double(targetFPS), repeats: true) { [weak self] timer in
            guard let self = self, self.isCapturing else {
                timer.invalidate()
                return
            }
            
            self.captureWindow(windowID: windowID)
        }
        
        isCapturing = true
    }
    
    private func captureWindow(windowID: CGWindowID) {
        autoreleasepool {
            let options = CGWindowListOption(arrayLiteral: .optionIncludingWindow)
            
            guard let image = CGWindowListCreateImage(
                .null,
                options,
                windowID,
                [.boundsIgnoreFraming, .bestResolution]
            ) else {
                return
            }
            
            if let pixelBuffer = convertToPixelBuffer(image: image) {
                let rotation = RTCVideoRotation._0
                let timeStampNs = Int64(CACurrentMediaTime() * 1_000_000_000)
                
                let rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
                let videoFrame = RTCVideoFrame(
                    buffer: rtcPixelBuffer,
                    rotation: rotation,
                    timeStampNs: timeStampNs
                )
                
                screenSource?.capturer(self as RTCVideoCapturer, didCapture: videoFrame)
            }
        }
    }
}

// MARK: - RTCVideoCapturer Extension

extension ScreenShareExample: RTCVideoCapturer {
    // RTCVideoCapturer conformance is handled by the framework
}