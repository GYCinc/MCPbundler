import sys

filepath = 'MCPBundler/Views/Servers/ServerDetailSheet.swift'

with open(filepath, 'r') as f:
    lines = f.readlines()

start_marker = '    private var authBadge: some View {'
end_marker = '    private var advancedOptionsCard: some View {'

new_block = [
    '    private var authBadge: some View {\n',
    '        // If no auth configured at all, indicate that neutrally and show no action button\n',
    '        if server.usesManualCredentials {\n',
    '            return AnyView(HealthBadge(status: .healthy, customLabel: "Manual Access", customIcon: "key.fill", customColor: .accentColor))\n',
    '        }\n',
    '        if !server.usesOAuthAuthorization {\n',
    '            return AnyView(HealthBadge(status: .unknown, customLabel: "No Authorization", customIcon: "minus.circle"))\n',
    '        }\n',
    '        // Map OAuthStatus to a Health-like badge appearance\n',
    '        let mapped: HealthStatus\n',
    '        switch server.oauthStatus {\n',
    '        case .authorized: mapped = .healthy\n',
    '        case .refreshing: mapped = .degraded\n',
    '        case .unauthorized, .error: mapped = .unhealthy\n',
    '        }\n',
    '        \n',
    '        let label: String\n',
    '        let icon: String?\n',
    '        switch mapped {\n',
    '        case .healthy:\n',
    '            label = "Signed In"\n',
    '            icon = "checkmark.circle.fill"\n',
    '        case .degraded:\n',
    '            label = "Refreshing"\n',
    '            icon = "clock.arrow.circlepath"\n',
    '        case .unhealthy:\n',
    '            label = (server.oauthStatus == .unauthorized) ? "Sign-in Required" : "Needs Attention"\n',
    '            icon = (server.oauthStatus == .unauthorized) ? "xmark.circle.fill" : "exclamationmark.triangle.fill"\n',
    '        case .unknown:\n',
    '            label = "Unknown"\n',
    '            icon = "questionmark.circle"\n',
    '        }\n',
    '        \n',
    '        return AnyView(HealthBadge(status: mapped, customLabel: label, customIcon: icon))\n',
    '    }\n',
    '\n'
]

output_lines = []
i = 0
found = False
in_block = False

while i < len(lines):
    line = lines[i]
    if line.rstrip() == start_marker.rstrip():
        found = True
        in_block = True
        output_lines.extend(new_block)
        i += 1
    elif in_block:
        if line.rstrip() == end_marker.rstrip():
            in_block = False
            output_lines.append(line)
            i += 1
        else:
            # skipping old block
            i += 1
    else:
        output_lines.append(line)
        i += 1

if not found:
    print("Error: Could not find the authBadge block.")
    sys.exit(1)

with open(filepath, 'w') as f:
    f.writelines(output_lines)

print("Successfully updated ServerDetailSheet.swift")
