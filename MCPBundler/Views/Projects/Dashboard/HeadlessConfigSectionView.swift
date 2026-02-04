//
//  HeadlessConfigSectionView.swift
//  MCP Bundler
//
//  Expandable section showing headless server configuration details.
//

import SwiftUI

struct HeadlessConfigSectionView: View {
    var executablePath: String
    var clientCount: Int

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.secondaryAccent.opacity(0.1))
                            .frame(width: 32, height: 32)

                        Image(systemName: "server.rack") // settings_input_component -> server.rack or terminal
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryAccent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Headless MCP Server Configuration")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("Installation guidance for clients")
                            .font(.system(size: 12))
                            .foregroundColor(.textMuted)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        Text("\(clientCount) Clients")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.05))
                            .foregroundColor(.textMuted)
                            .cornerRadius(4)

                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .foregroundColor(.textMuted)
                    }
                }
                .padding(16)
                .background(Color.white.opacity(isExpanded ? 0.02 : 0))
            }
            .buttonStyle(.plain)

            // Content
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()
                        .background(Color.white.opacity(0.05))

                    HStack(alignment: .top, spacing: 24) {
                        // Command Line
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("COMMAND LINE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.textMuted)
                                    .tracking(1)
                                Spacer()
                                CopyButton(text: commandLine)
                            }

                            Text(commandLine)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondaryAccent)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.bgDeep)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }

                        // JSON Config
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("JSON CONFIG")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.textMuted)
                                    .tracking(1)
                                Spacer()
                                CopyButton(text: jsonConfig)
                            }

                            Text(jsonConfig)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.softBlue)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.bgDeep)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                    .padding(16)
                    .padding(.top, 0)
                }
                .background(Color.black.opacity(0.2))
            }
        }
        .background(Color.slate900.opacity(0.5))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }

    private var commandLine: String {
        "\(executablePath) --stdio-server"
    }

    private var jsonConfig: String {
        #"{"mcp-bundler": {"command": "...", "args": ["--stdio-server"]}}"#
    }
}

private struct CopyButton: View {
    let text: String
    @State private var isCopied = false

    var body: some View {
        Button(action: {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            withAnimation {
                isCopied = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isCopied = false
                }
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                Text(isCopied ? "Copied" : "Copy")
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(isCopied ? .green : .primaryAccent)
        }
        .buttonStyle(.plain)
    }
}
