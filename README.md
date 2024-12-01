# Noice: A One-Time Pad (OTP) Encryption CLI Tool

Noice is a command-line interface (CLI) tool designed to implement One-Time Pad (OTP) encryption. Written in the Zig programming language, Noice provides a fast, secure, and reliable way to cipher and decipher messages using the OTP encryption scheme. It also includes a token generator to facilitate the secure sharing of the encryption key, which is crucial for the OTP method.

## What is One-Time Pad (OTP)?

One-Time Pad (OTP) is a symmetric encryption technique where a plaintext message is combined with a random key (or pad) of the same length. Each character in the plaintext is XORed with the corresponding character in the key, resulting in ciphertext that is completely random and theoretically unbreakable, provided certain conditions are met:

1. **The key is truly random**: The key must be generated in such a way that it cannot be predicted or reproduced.
2. **The key is as long as the plaintext**: For OTP to be secure, the key must be at least as long as the message being encrypted.
3. **The key is used only once**: The key must never be reused for another message, hence the name "one-time."

OTP encryption provides perfect secrecy and has been proven mathematically to be secure if the above conditions are met.

## Why Zig?

Zig is a systems programming language designed for simplicity, safety, and performance. Choosing Zig to implement Noice provides several benefits:

- **Performance**: Zig is a compiled language that generates highly optimized binaries. It is known for its low overhead and minimal runtime, which is ideal for cryptographic applications where performance is crucial.
- **Memory Safety**: Zig provides strong compile-time checks that reduce the risk of bugs, such as buffer overflows, which are especially important in security-critical applications.
- **Cross-compilation**: Zig makes it easy to compile to various platforms, making Noice easily portable to different operating systems and architectures without requiring complex setup.
- **Simplicity**: Zig's syntax is straightforward, and it avoids unnecessary abstractions, providing a clear and concise implementation that is easy to understand and maintain.

By using Zig, Noice leverages the power of a low-level language while benefiting from strong safety features, speed, and portability.

## Key Security Note
Since OTP encryption relies on the secrecy of the key, it is essential that the key is never transmitted in plaintext over insecure channels. Use secure methods (e.g., physical transfer, encrypted communication) to share the one-time pad between the sender and the recipient.
