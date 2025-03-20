#!/usr/bin/env python3
import os
import re
import argparse
from pathlib import Path


def remove_uids_from_file(filepath):
    """Remove all UIDs from a Godot scene file."""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()

        original_content = content

        # Remove UIDs from ext_resource entries
        # Pattern matches: [ext_resource type="X" uid="X" path="X"]
        modified_content = re.sub(
            r'(ext_resource\s+[^]]*?)uid="[^"]*"(\s+[^]]*?\])', r"\1\2", content
        )

        # If content was changed, write it back
        if modified_content != original_content:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(modified_content)
            return True

        return False
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False


def delete_uid_cache(project_path):
    """Delete the UID cache file to force regeneration."""
    uid_cache = project_path / ".godot" / "uid_cache.bin"

    if uid_cache.exists():
        try:
            uid_cache.unlink()
            print(f"Deleted UID cache: {uid_cache}")
            return True
        except Exception as e:
            print(f"Error deleting UID cache: {e}")
            return False
    else:
        print(f"UID cache not found: {uid_cache}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Remove UIDs from Godot project files to force regeneration"
    )
    parser.add_argument(
        "project_path",
        nargs="?",
        default=os.getcwd(),
        help="Path to Godot project (default: current directory)",
    )

    args = parser.parse_args()
    project_path = Path(args.project_path)

    print(f"Scanning for scene files in: {project_path}")

    # Find all scene files
    scene_files = list(project_path.glob("**/*.tscn"))
    resource_files = list(project_path.glob("**/*.tres"))
    all_files = scene_files + resource_files

    modified_count = 0
    for file_path in all_files:
        print(f"Processing: {file_path}")
        if remove_uids_from_file(file_path):
            modified_count += 1

    print(f"Modified {modified_count} files")

    # Delete the UID cache
    delete_uid_cache(project_path)

    print("\nUID removal complete! Please restart Godot to regenerate UIDs.")
    print(
        "If errors persist, try renaming the .godot folder to force a full project reimport."
    )


if __name__ == "__main__":
    main()
