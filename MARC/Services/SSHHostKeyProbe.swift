import Foundation
import NIOSSH
import NIOCore
import NIOPosix

/// Ends key exchange before authentication. Never owns a password.
private struct HostKeyObserved: Error, Sendable {
    let publicKey: String
    nonisolated init(publicKey: String) { self.publicKey = publicKey }
}

struct HostProbeTimeout: LocalizedError, Sendable {
    nonisolated var errorDescription: String? { "The Mac did not provide an SSH host key within 10 seconds. Check Remote Login and try again." }
    nonisolated init() {}
}

private final class ProbeHostKeyDelegate: NIOSSHClientServerAuthenticationDelegate, Sendable {
    nonisolated init() {}
    nonisolated func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
        validationCompletePromise.fail(HostKeyObserved(publicKey: String(openSSHPublicKey: hostKey)))
    }
}

private final class ProbeNoAuthentication: NIOSSHClientUserAuthenticationDelegate, Sendable {
    nonisolated init() {}
    nonisolated func nextAuthenticationType(
        availableMethods: NIOSSHAvailableUserAuthenticationMethods,
        nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>
    ) {
        nextChallengePromise.succeed(nil)
    }
}

private final class ProbeErrorHandler: ChannelInboundHandler, Sendable {
    typealias InboundIn = ByteBuffer
    private let result: EventLoopPromise<String>
    nonisolated init(result: EventLoopPromise<String>) { self.result = result }
    nonisolated func errorCaught(context: ChannelHandlerContext, error: Error) {
        result.fail(error)
        context.close(promise: nil)
    }
    nonisolated func channelInactive(context: ChannelHandlerContext) {
        result.fail(ChannelError.eof)
        context.fireChannelInactive()
    }
}

enum SSHHostKeyProbe {
    static func fetch(server: ServerProfile) async throws -> String {
        let eventLoop = MultiThreadedEventLoopGroup.singleton.next()
        let result = eventLoop.makePromise(of: String.self)
        let deadline = eventLoop.scheduleTask(in: .seconds(10)) {
            result.fail(HostProbeTimeout())
        }
        defer { deadline.cancel() }
        // Install SSH handlers before the socket opens, so no banner can be lost.
        let channel: Channel
        do {
            channel = try await ClientBootstrap(group: eventLoop)
                .connectTimeout(.seconds(10))
                .channelInitializer { channel in
                    channel.pipeline.addHandlers(
                        NIOSSHHandler(
                            role: .client(SSHClientConfiguration(
                                userAuthDelegate: ProbeNoAuthentication(),
                                serverAuthDelegate: ProbeHostKeyDelegate()
                            )),
                            allocator: channel.allocator,
                            inboundChildChannelInitializer: nil
                        ),
                        ProbeErrorHandler(result: result)
                    )
                }
                .connect(host: server.host, port: server.port).get()
        } catch {
            result.fail(error)
            throw error
        }
        do {
            _ = try await result.futureResult.get()
            try? await channel.close().get()
            throw SSHTestError.invalidKey
        } catch let observed as HostKeyObserved {
            try? await channel.close().get()
            try Task.checkCancellation()
            return observed.publicKey
        } catch {
            try? await channel.close().get()
            throw error
        }
    }
}
