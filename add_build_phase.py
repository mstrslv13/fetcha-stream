#!/usr/bin/env python3
"""
Add 'Fix Binary Permissions' build phase to Xcode project.
This ensures bundled binaries have executable permissions.
"""

import re
import sys
import uuid
import os

def generate_uuid():
    """Generate a 24-character hex UUID for Xcode."""
    return uuid.uuid4().hex[:24].upper()

def add_build_phase(pbxproj_path):
    """Add the Fix Binary Permissions build phase."""
    
    with open(pbxproj_path, 'r') as f:
        content = f.read()
    
    # Check if build phase already exists
    if 'Fix Binary Permissions' in content:
        print("✓ 'Fix Binary Permissions' build phase already exists")
        return
    
    # Generate UUIDs for new entries
    script_phase_ref = generate_uuid()
    script_build_ref = generate_uuid()
    
    # The script to add (escaped for Xcode)
    script_content = ('# Fix permissions for bundled binaries\\n'
                      'if [ -d \\"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/bin\\" ]; then\\n'
                      '    chmod +x \\"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/bin/yt-dlp\\"\\n'
                      '    chmod +x \\"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/bin/ffmpeg\\"\\n'
                      '    chmod +x \\"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/bin/ffprobe\\"\\n'
                      '    echo \\"Fixed binary permissions\\"\\n'
                      'else\\n'
                      '    echo \\"No bundled binaries found\\"\\n'
                      'fi')
    
    # Find the PBXShellScriptBuildPhase section
    shell_section = re.search(r'(/\* Begin PBXShellScriptBuildPhase section \*/.*?/\* End PBXShellScriptBuildPhase section \*/)', 
                              content, re.DOTALL)
    
    if not shell_section:
        # Section doesn't exist, create it
        native_target_match = re.search(r'/\* End PBXResourcesBuildPhase section \*/', content)
        if native_target_match:
            new_section = f'''
/* Begin PBXShellScriptBuildPhase section */
		{script_phase_ref} /* Fix Binary Permissions */ = {{
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputFileListPaths = (
			);
			inputPaths = (
			);
			name = "Fix Binary Permissions";
			outputFileListPaths = (
			);
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "{script_content}";
		}};
/* End PBXShellScriptBuildPhase section */
'''
            content = content.replace('/\* End PBXResourcesBuildPhase section */', 
                                      '/\* End PBXResourcesBuildPhase section */' + new_section)
    else:
        # Add to existing section
        new_phase = f'''		{script_phase_ref} /* Fix Binary Permissions */ = {{
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputFileListPaths = (
			);
			inputPaths = (
			);
			name = "Fix Binary Permissions";
			outputFileListPaths = (
			);
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "{script_content}";
		}};
'''
        content = content.replace('/* End PBXShellScriptBuildPhase section */', 
                                  new_phase + '/* End PBXShellScriptBuildPhase section */')
    
    # Add to the main target's build phases
    target_match = re.search(r'(F8522F062E588C4300B30F2A /\* yt-dlp-MAX \*/ = {[^}]*buildPhases = \([^)]+)\);', 
                             content, re.DOTALL)
    
    if target_match:
        build_phases = target_match.group(1)
        if script_phase_ref not in build_phases:
            # Add after Resources phase
            new_phases = build_phases + f',\n\t\t\t\t{script_phase_ref} /* Fix Binary Permissions */,'
            content = content.replace(build_phases + ');', new_phases + '\n\t\t\t);')
    
    # Write the modified content back
    with open(pbxproj_path, 'w') as f:
        f.write(content)
    
    print("✓ Successfully added 'Fix Binary Permissions' build phase")
    print("✓ The build phase will run after copying resources")
    print("✓ It will ensure yt-dlp, ffmpeg, and ffprobe are executable")

if __name__ == "__main__":
    pbxproj_path = "/Users/mstrslv/devspace/yt-dlp-MAX/yt-dlp-MAX.xcodeproj/project.pbxproj"
    
    if not os.path.exists(pbxproj_path):
        print(f"Error: project.pbxproj not found at {pbxproj_path}")
        sys.exit(1)
    
    add_build_phase(pbxproj_path)