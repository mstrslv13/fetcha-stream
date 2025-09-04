#!/usr/bin/env python3
"""
Add Resources folder to Xcode project for bundling binaries.
This script modifies the project.pbxproj file to include the Resources/bin folder.
"""

import re
import sys
import uuid
import os

def generate_uuid():
    """Generate a 24-character hex UUID for Xcode."""
    return uuid.uuid4().hex[:24].upper()

def add_resources_to_project(pbxproj_path):
    """Add Resources folder to the Xcode project file."""
    
    with open(pbxproj_path, 'r') as f:
        content = f.read()
    
    # Check if Resources is already added
    if 'Resources/bin' in content or 'Resources folder' in content:
        print("✓ Resources folder appears to already be in the project")
        return
    
    # Generate UUIDs for new entries
    resources_folder_ref = generate_uuid()
    bin_folder_ref = generate_uuid()
    ytdlp_ref = generate_uuid()
    ffmpeg_ref = generate_uuid()
    ffprobe_ref = generate_uuid()
    
    resources_build_ref = generate_uuid()
    
    # Find the PBXFileReference section
    file_ref_section = re.search(r'(/\* Begin PBXFileReference section \*/.*?/\* End PBXFileReference section \*/)', 
                                  content, re.DOTALL)
    
    if not file_ref_section:
        print("Error: Could not find PBXFileReference section")
        return
    
    # Add file references
    new_refs = f"""		{resources_folder_ref} /* Resources */ = {{isa = PBXFileReference; lastKnownFileType = folder; path = Resources; sourceTree = "<group>"; }};
		{bin_folder_ref} /* bin */ = {{isa = PBXFileReference; lastKnownFileType = folder; path = bin; sourceTree = "<group>"; }};
		{ytdlp_ref} /* yt-dlp */ = {{isa = PBXFileReference; lastKnownFileType = "compiled.mach-o.executable"; path = "yt-dlp"; sourceTree = "<group>"; }};
		{ffmpeg_ref} /* ffmpeg */ = {{isa = PBXFileReference; lastKnownFileType = "compiled.mach-o.executable"; path = ffmpeg; sourceTree = "<group>"; }};
		{ffprobe_ref} /* ffprobe */ = {{isa = PBXFileReference; lastKnownFileType = "compiled.mach-o.executable"; path = ffprobe; sourceTree = "<group>"; }};
"""
    
    # Insert before the end of PBXFileReference section
    content = content.replace('/* End PBXFileReference section */', 
                              new_refs + '/* End PBXFileReference section */')
    
    # Find the PBXGroup section for the main project
    main_group_match = re.search(r'(F8522EFE2E588C4300B30F2A /\* Project object \*/.*?mainGroup = )([A-F0-9]+)', 
                                  content, re.DOTALL)
    
    if main_group_match:
        main_group_id = main_group_match.group(2)
        
        # Find the main group definition
        main_group_pattern = f'{main_group_id} = {{[^}}]*children = \\(([^\\)]+)\\);'
        main_group_match = re.search(main_group_pattern, content)
        
        if main_group_match:
            children = main_group_match.group(1)
            # Add Resources folder to children if not already there
            if resources_folder_ref not in children:
                new_children = children.rstrip() + f',\n\t\t\t\t{resources_folder_ref} /* Resources */,'
                content = content.replace(f'children = ({children});', 
                                          f'children = ({new_children}\n\t\t\t);')
    
    # Add Resources group definition
    group_section = re.search(r'(/\* Begin PBXGroup section \*/.*?/\* End PBXGroup section \*/)', 
                              content, re.DOTALL)
    
    if group_section:
        resources_group = f"""		{resources_folder_ref} /* Resources */ = {{
			isa = PBXGroup;
			children = (
				{bin_folder_ref} /* bin */,
			);
			path = Resources;
			sourceTree = "<group>";
		}};
		{bin_folder_ref} /* bin */ = {{
			isa = PBXGroup;
			children = (
				{ytdlp_ref} /* yt-dlp */,
				{ffmpeg_ref} /* ffmpeg */,
				{ffprobe_ref} /* ffprobe */,
			);
			path = bin;
			sourceTree = "<group>";
		}};
"""
        content = content.replace('/* End PBXGroup section */', 
                                  resources_group + '/* End PBXGroup section */')
    
    # Find the PBXResourcesBuildPhase section for the main target
    resources_phase_match = re.search(
        r'(/\* Begin PBXResourcesBuildPhase section \*/.*?)(F8522F052E588C4300B30F2A /\* Resources \*/ = {[^}]*files = \([^)]*\);)',
        content, re.DOTALL
    )
    
    if resources_phase_match:
        resources_section = resources_phase_match.group(2)
        # Add Resources folder to build phase
        if resources_build_ref not in resources_section:
            new_build_file = f'\t\t\t\t{resources_build_ref} /* Resources in Resources */,'
            content = content.replace(
                resources_section,
                resources_section.replace('files = (', f'files = (\n{new_build_file}')
            )
    
    # Add to PBXBuildFile section
    build_file_section = re.search(r'(/\* Begin PBXBuildFile section \*/.*?/\* End PBXBuildFile section \*/)', 
                                    content, re.DOTALL)
    
    if build_file_section:
        new_build_file = f"""		{resources_build_ref} /* Resources in Resources */ = {{isa = PBXBuildFile; fileRef = {resources_folder_ref} /* Resources */; }};
"""
        content = content.replace('/* End PBXBuildFile section */', 
                                  new_build_file + '/* End PBXBuildFile section */')
    
    # Write the modified content back
    with open(pbxproj_path, 'w') as f:
        f.write(content)
    
    print("✓ Successfully added Resources folder to Xcode project")
    print("⚠️  Note: You still need to:")
    print("   1. Open the project in Xcode")
    print("   2. Verify Resources folder appears in the project navigator")
    print("   3. Check Build Phases → Copy Bundle Resources includes Resources folder")
    print("   4. Add the 'Fix Binary Permissions' build phase script")

if __name__ == "__main__":
    pbxproj_path = "/Users/mstrslv/devspace/yt-dlp-MAX/yt-dlp-MAX.xcodeproj/project.pbxproj"
    
    if not os.path.exists(pbxproj_path):
        print(f"Error: project.pbxproj not found at {pbxproj_path}")
        sys.exit(1)
    
    # Backup the original file
    backup_path = pbxproj_path + ".backup"
    with open(pbxproj_path, 'r') as f:
        backup_content = f.read()
    with open(backup_path, 'w') as f:
        f.write(backup_content)
    print(f"✓ Backed up project file to {backup_path}")
    
    add_resources_to_project(pbxproj_path)