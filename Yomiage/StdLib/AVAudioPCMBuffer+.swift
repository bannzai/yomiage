import AVFoundation

// Ref: https://stackoverflow.com/questions/59881955/combining-avaudiopcmbuffers
extension AVAudioPCMBuffer {
  func append(_ buffer: AVAudioPCMBuffer) {
    append(buffer, startingFrame: 0, frameCount: buffer.frameLength)
  }

  func append(_ buffer: AVAudioPCMBuffer, startingFrame: AVAudioFramePosition, frameCount: AVAudioFrameCount) {
    precondition(format == buffer.format, "Format mismatch")
    precondition(startingFrame + AVAudioFramePosition(frameCount) <= AVAudioFramePosition(buffer.frameLength), "Insufficient audio in buffer")
    precondition(frameLength + frameCount <= frameCapacity, "Insufficient space in buffer")

    let dst = floatChannelData!
    let src = buffer.floatChannelData!

    memcpy(dst.pointee.advanced(by: stride * Int(frameLength)),
           src.pointee.advanced(by: stride * Int(startingFrame)),
           Int(frameCount) * stride * MemoryLayout<Float>.size)

    frameLength += frameCount
  }

  convenience init?(concatenating buffers: AVAudioPCMBuffer...) {
    precondition(buffers.count > 0)
    let totalFrames = buffers.reduce(0, { $1.frameLength })
    self.init(pcmFormat: buffers[0].format, frameCapacity: totalFrames)
    buffers.forEach { append($0) }
  }
}
