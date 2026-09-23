//
//  OpenglView.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import Darwin
import GLKit
import MobileRTC
import OpenGLES
import QuartzCore
import UIKit
import os

enum DisplayMode {
    case letterBox
    case panAndScan
}

private let attribVertex: GLuint = 0
private let attribTexture: GLuint = 1

private let fragmentShaderSource = """
varying lowp vec2 TexCoordOut;
uniform sampler2D SamplerY;
uniform sampler2D SamplerU;
uniform sampler2D SamplerV;
void main(void) {
    mediump vec3 yuv;
    lowp vec3 rgb;
    yuv.x = texture2D(SamplerY, TexCoordOut).r;
    yuv.y = texture2D(SamplerU, TexCoordOut).r - 0.5;
    yuv.z = texture2D(SamplerV, TexCoordOut).r - 0.5;
    rgb = mat3(1.0, 1.0, 1.0,
               0.0, -0.39465, 2.03211,
               1.13983, -0.58060, 0.0) * yuv;
    gl_FragColor = vec4(rgb, 1.0);
}
"""

private let vertexShaderSource = """
attribute vec4 position;
attribute vec2 TexCoordIn;
varying vec2 TexCoordOut;
void main(void) {
    gl_Position = position;
    TexCoordOut = TexCoordIn;
}
"""

private let backgroundTag = 10003
private let emojiTag = 10002

final class OpenglView: UIView {

    private var glContext: EAGLContext?
    private var framebuffer: GLuint = 0
    private var renderBuffer: GLuint = 0
    private var program: GLuint = 0
    private var textureYUV: [GLuint] = [0, 0, 0]
    private var videoW: GLuint = 0
    private var videoH: GLuint = 0
    private var viewScale: GLsizei = 1
    private var boundSize: CGSize = .zero
    private var displayMode: DisplayMode = .panAndScan
    private var enterBackground: Bool = false
    private var lock = pthread_mutex_t()

    override class var layerClass: AnyClass { CAEAGLLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        boundSize = frame.size
        if !doInit() {
            return
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        if !doInit() {
            return nil
        }
    }

    deinit {
        clearFrame()
        destroyFrameAndRenderBuffer()
        pthread_mutex_destroy(&lock)
        NotificationCenter.default.removeObserver(self)
    }

    private func doInit() -> Bool {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

        backgroundColor = .black
        if let eaglLayer = layer as? CAEAGLLayer {
            eaglLayer.isOpaque = true
            eaglLayer.drawableProperties = [
                kEAGLDrawablePropertyRetainedBacking as String: false,
                kEAGLDrawablePropertyColorFormat as String: kEAGLColorFormatRGB565
            ]
        }
        contentScaleFactor = UIScreen.main.scale
        viewScale = GLsizei(UIScreen.main.scale)
        glContext = EAGLContext(api: .openGLES2)
        guard let glContext, EAGLContext.setCurrent(glContext) else { return false }
        guard setupYUVTexture() else { return false }
        loadShader()
        glPixelStorei(GLenum(GL_UNPACK_ALIGNMENT), 1)
        glUseProgram(program)
        glUniform1i(glGetUniformLocation(program, "SamplerY"), 0)
        glUniform1i(glGetUniformLocation(program, "SamplerU"), 1)
        glUniform1i(glGetUniformLocation(program, "SamplerV"), 2)
        pthread_mutex_init(&lock, nil)
        return true
    }

    private func setupYUVTexture() -> Bool {
        if textureYUV[0] != 0 {
            glDeleteTextures(3, &textureYUV)
        }
        glGenTextures(3, &textureYUV)
        guard textureYUV[0] != 0, textureYUV[1] != 0, textureYUV[2] != 0 else { return false }
        for i in 0..<3 {
            glActiveTexture(GLenum(GL_TEXTURE0 + Int32(i)))
            glBindTexture(GLenum(GL_TEXTURE_2D), textureYUV[i])
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        }
        return true
    }

    private func compileShader(_ shaderSource: String, type: GLenum) -> GLuint {
        let handle = glCreateShader(type)
        var cString = (shaderSource as NSString).utf8String
        var length = GLint(shaderSource.utf8.count)
        glShaderSource(handle, 1, &cString, &length)
        glCompileShader(handle)
        var status: GLint = 0
        glGetShaderiv(handle, GLenum(GL_COMPILE_STATUS), &status)
        if status == GL_FALSE {
            Logger.info("shader compile failed")
        }
        return handle
    }

    private func loadShader() {
        let vertexShader = compileShader(vertexShaderSource, type: GLenum(GL_VERTEX_SHADER))
        let fragmentShader = compileShader(fragmentShaderSource, type: GLenum(GL_FRAGMENT_SHADER))
        program = glCreateProgram()
        glAttachShader(program, vertexShader)
        glAttachShader(program, fragmentShader)
        glBindAttribLocation(program, attribVertex, "position")
        glBindAttribLocation(program, attribTexture, "TexCoordIn")
        glLinkProgram(program)
        var linkSuccess: GLint = 0
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &linkSuccess)
        if linkSuccess == GL_FALSE {
            Logger.info("shader link failed")
        }
        glDeleteShader(vertexShader)
        glDeleteShader(fragmentShader)
    }

    private func destroyFrameAndRenderBuffer() {
        if framebuffer != 0 { glDeleteFramebuffers(1, &framebuffer); framebuffer = 0 }
        if renderBuffer != 0 { glDeleteRenderbuffers(1, &renderBuffer); renderBuffer = 0 }
    }

    @discardableResult
    private func createFrameAndRenderBuffer() -> Bool {
        glGenFramebuffers(1, &framebuffer)
        glGenRenderbuffers(1, &renderBuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), renderBuffer)
        if let eaglLayer = layer as? CAEAGLLayer {
            _ = glContext?.renderbufferStorage(Int(GL_RENDERBUFFER), from: eaglLayer)
        }
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), renderBuffer)
        return glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER)) == GL_FRAMEBUFFER_COMPLETE
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        boundSize = frame.size
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            pthread_mutex_lock(&self.lock)
            if let context = self.glContext { EAGLContext.setCurrent(context) }
            self.destroyFrameAndRenderBuffer()
            self.createFrameAndRenderBuffer()
            pthread_mutex_unlock(&self.lock)
            glViewport(1, 1, GLsizei(self.bounds.size.width) * self.viewScale - 2, GLsizei(self.bounds.size.height) * self.viewScale - 2)
        }
        for subView in subviews {
            if subView.tag == backgroundTag {
                subView.frame = bounds
            }
            if subView.tag == emojiTag {
                subView.frame = CGRect(x: bounds.size.width * 0.25, y: bounds.size.height * 0.25, width: bounds.size.width * 0.5, height: bounds.size.height * 0.5)
            }
        }
    }

    func clearFrame() {
        guard window != nil else { return }
        pthread_mutex_lock(&lock)
        if let glContext { EAGLContext.setCurrent(glContext) }
        glClearColor(0, 0, 0, 1)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), renderBuffer)
        _ = glContext?.presentRenderbuffer(Int(GL_RENDERBUFFER))
        pthread_mutex_unlock(&lock)
    }

    private func setVideoWidth(_ width: GLuint, height: GLuint) {
        videoH = height
        videoW = width
        let bufferSize = (Int(width) * Int(height) * 3 + 1) / 2
        let blackData = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        memset(blackData, 0, bufferSize)
        defer { blackData.deallocate() }
        if let glContext { EAGLContext.setCurrent(glContext) }
        glBindTexture(GLenum(GL_TEXTURE_2D), textureYUV[0])
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RED_EXT, GLsizei(width), GLsizei(height), 0, GLenum(GL_RED_EXT), GLenum(GL_UNSIGNED_BYTE), blackData)
        glBindTexture(GLenum(GL_TEXTURE_2D), textureYUV[1])
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RED_EXT, GLsizei((width + 1) / 2), GLsizei((height + 1) / 2), 0, GLenum(GL_RED_EXT), GLenum(GL_UNSIGNED_BYTE), blackData.advanced(by: Int(width) * Int(height)))
        glBindTexture(GLenum(GL_TEXTURE_2D), textureYUV[2])
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RED_EXT, GLsizei((width + 1) / 2), GLsizei((height + 1) / 2), 0, GLenum(GL_RED_EXT), GLenum(GL_UNSIGNED_BYTE), blackData.advanced(by: (Int(width) * Int(height) * 5 + 1) / 4))
    }

    func displayYUV(_ rawData: MobileRTCVideoRawData, mode: DisplayMode, mirror: Bool) {
        guard !enterBackground else { return }
        let w = Int(rawData.size.width)
        let h = Int(rawData.size.height)
        guard w > 0, h > 0, let yBuffer = rawData.yBuffer else { return }
        let bufferLen = w * h

        var maskedY: UnsafeMutablePointer<Int8>? = nil
        defer { maskedY?.deallocate() }
        if let alpha = rawData.alphaBuffer, Int(rawData.alphaBufferLen) == bufferLen {
            let buf = UnsafeMutablePointer<Int8>.allocate(capacity: bufferLen)
            for idx in 0..<bufferLen {
                buf[idx] = ((alpha[idx] & 1) == 1) ? yBuffer[idx] : 0
            }
            maskedY = buf
        }

        pthread_mutex_lock(&lock)
        if w != Int(videoW) || h != Int(videoH) {
            setVideoWidth(GLuint(w), height: GLuint(h))
        }
        if mode != displayMode {
            displayMode = mode
        }
        if let glContext { EAGLContext.setCurrent(glContext) }
        glBindTexture(GLenum(GL_TEXTURE_2D), textureYUV[0])
        glTexSubImage2D(
            GLenum(GL_TEXTURE_2D), 0, 0, 0, GLsizei(w), GLsizei(h),
            GLenum(GL_RED_EXT), GLenum(GL_UNSIGNED_BYTE),
            maskedY.map(UnsafeRawPointer.init) ?? UnsafeRawPointer(yBuffer)
        )
        if let uBuffer = rawData.uBuffer {
            glBindTexture(GLenum(GL_TEXTURE_2D), textureYUV[1])
            glTexSubImage2D(GLenum(GL_TEXTURE_2D), 0, 0, 0, GLsizei((w + 1) / 2), GLsizei((h + 1) / 2), GLenum(GL_RED_EXT), GLenum(GL_UNSIGNED_BYTE), uBuffer)
        }
        if let vBuffer = rawData.vBuffer {
            glBindTexture(GLenum(GL_TEXTURE_2D), textureYUV[2])
            glTexSubImage2D(GLenum(GL_TEXTURE_2D), 0, 0, 0, GLsizei((w + 1) / 2), GLsizei((h + 1) / 2), GLenum(GL_RED_EXT), GLenum(GL_UNSIGNED_BYTE), vBuffer)
        }
        renderWithRotate(rotate: rawData.rotation, rawSize: rawData.size, mode: mode, mirror: mirror)
        pthread_mutex_unlock(&lock)
    }

    private func renderWithRotate(rotate: MobileRTCVideoRawDataRotation, rawSize: CGSize, mode: DisplayMode, mirror: Bool) {
        glClearColor(0, 0, 0, 1)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        if let glContext { EAGLContext.setCurrent(glContext) }
        glViewport(1, 1, GLsizei(boundSize.width) * viewScale - 2, GLsizei(boundSize.height) * viewScale - 2)

        let coordVertices: [GLfloat] = [0, 1, 1, 1, 0, 0, 1, 0]
        glVertexAttribPointer(attribTexture, 2, GLenum(GL_FLOAT), 0, 0, coordVertices)
        glEnableVertexAttribArray(attribTexture)

        let cropSize = cropSize(rawSize: rawSize, mode: mode, rotate: rotate)
        let w = GLfloat(cropSize.width)
        let h = GLfloat(cropSize.height)

        let squareVertices: [GLfloat]
        switch rotate {
        case .rotationNone:
            squareVertices = mirror
                ? [-w, -h, w, -h, -w, h, w, h]
                : [w, -h, -w, -h, w, h, -w, h]
        case .rotation90:
            squareVertices = mirror
                ? [w, h, w, -h, -w, h, -w, -h]
                : [-w, h, -w, -h, w, h, w, -h]
        case .rotation180:
            squareVertices = mirror
                ? [-w, h, w, h, -w, -h, w, -h]
                : [w, h, -w, h, w, -h, -w, -h]
        case .rotation270:
            squareVertices = mirror
                ? [-w, -h, -w, h, w, -h, w, h]
                : [w, -h, w, h, -w, -h, -w, h]
        default:
            squareVertices = [w, -h, -w, -h, w, h, -w, h]
        }

        glVertexAttribPointer(attribVertex, 2, GLenum(GL_FLOAT), 0, 0, squareVertices)
        glEnableVertexAttribArray(attribVertex)
        glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), renderBuffer)
        _ = glContext?.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }

    private func cropSize(rawSize: CGSize, mode: DisplayMode, rotate: MobileRTCVideoRawDataRotation) -> CGSize {
        let display = boundSize
        var source = rawSize
        if rotate == .rotation90 || rotate == .rotation270 {
            source = CGSize(width: rawSize.height, height: rawSize.width)
        }
        guard display.width > 0, display.height > 0, source.width > 0, source.height > 0 else { return .zero }
        let cropScale = CGSize(width: source.width / display.width, height: source.height / display.height)
        var cropSize = CGSize.zero
        switch mode {
        case .panAndScan:
            if cropScale.width > cropScale.height {
                cropSize.height = 1.0
                cropSize.width = cropScale.width / cropScale.height
            } else {
                cropSize.width = 1.0
                cropSize.height = cropScale.height / cropScale.width
            }
        case .letterBox:
            if cropScale.width > cropScale.height {
                cropSize.width = 1.0
                cropSize.height = cropScale.height / cropScale.width
            } else {
                cropSize.height = 1.0
                cropSize.width = cropScale.width / cropScale.height
            }
        }
        return cropSize
    }

    func addAvatar() {
        let bgView = UIView(frame: bounds)
        bgView.backgroundColor = UIColor(red: 0x23/255.0, green: 0x23/255.0, blue: 0x23/255.0, alpha: 1)
        bgView.tag = backgroundTag
        addSubview(bgView)
        sendSubviewToBack(bgView)

        if let image = UIImage(named: "default_avatar") {
            let imageView = UIImageView(image: image)
            imageView.frame = CGRect(x: bounds.size.width * 0.25, y: bounds.size.height * 0.25, width: bounds.size.width * 0.5, height: bounds.size.height * 0.5)
            imageView.contentMode = .scaleAspectFit
            imageView.tag = emojiTag
            addSubview(imageView)
        }
    }

    func removeAvatar() {
        for view in subviews where view.tag == emojiTag || view.tag == backgroundTag {
            view.removeFromSuperview()
        }
    }

    @objc private func applicationWillResignActive() { enterBackground = true }
    @objc private func applicationDidBecomeActive() { enterBackground = false }
}
