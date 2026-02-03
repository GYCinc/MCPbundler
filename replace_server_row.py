import sys

filepath = 'MCPBundler/Views/Projects/ProjectDetailView.swift'

with open(filepath, 'r') as f:
    lines = f.readlines()

start_marker = '                    case .server(let server, let folder):'
end_marker = '                        .onDrag {'
closure_end_marker = '                        }'

new_block = [
    '                    case .server(let server, let folder):\n',
    '                        ServerRow(server: server, folder: folder)\n',
    '                            .contentShape(Rectangle())\n',
    '                            .frame(maxWidth: .infinity, alignment: .leading)\n',
    '                            .background(rowHighlight(for: server))\n',
    '                            .onDrag {\n',
    '                                beginDrag(for: server, source: "name")\n',
    '                            }\n'
]

output_lines = []
i = 0
found = False

while i < len(lines):
    line = lines[i]
    if line.rstrip() == start_marker.rstrip():
        # Found the start
        found = True
        output_lines.extend(new_block)

        # Skip lines until we find the end of the block we are replacing
        # The block ends after onDrag closure closing brace.
        # But wait, my end_marker '                        .onDrag {' is inside the block I want to skip?
        # The block I want to skip starts right after 'case .server...' and ends... where?

        # Let's count braces or look for the specific lines.
        # The block to remove is:
        # let effectiveEnabled ...
        # ...
        # .onDrag {
        #    beginDrag(...)
        # }

        # Easier: Scan forward until we see '                    }' (closing the case)?
        # No, the case doesn't have braces, it's just indented.
        # The next case starts with '                TableColumn("Tools")'.
        # Ah, 'TableColumn("Name") { item in' ... '}'

        # Let's look for the next TableColumn? No.

        # Let's match the specific block structure.
        # I want to skip until I see 'beginDrag(for: server, source: "name")' and then the closing brace.

        while i < len(lines):
             if 'beginDrag(for: server, source: "name")' in lines[i]:
                 # Skip this line
                 i += 1
                 # Skip the next line which should be closing brace for onDrag
                 if '}' in lines[i]:
                     i += 1
                 break
             i += 1
    else:
        output_lines.append(line)
        i += 1

if not found:
    print("Error: Could not find the target block.")
    sys.exit(1)

with open(filepath, 'w') as f:
    f.writelines(output_lines)

print("Successfully updated ProjectDetailView.swift")
