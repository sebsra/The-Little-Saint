"""
Project Structure Scanner

This script scans directories and creates a detailed report of the project structure,
including directory hierarchy and file contents. It's useful for documenting
project organization or sharing code structure.
"""

import os
import argparse
from pathlib import Path

text_extensions = {
    ".py",
    ".txt",
    ".md",
    ".json",
    ".yaml",
    ".yml",
    ".html",
    ".css",
    ".js",
    ".gd",
    ".godot",
}

include_extensions = text_extensions.union(
    {
        ".tscn",
    }
)

excluded_dirs = {"__pycache__", ".venv", "venv", ".git", "node_modules"}


def list_project_structure(directory, indent="", output_file=None, file_list=None):
    """Recursively lists all files and directories, excluding specified directories.

    Args:
        directory (str): The directory path to scan
        indent (str): Current indentation level for output formatting
        output_file: File object to write output to
        file_list (list): List to collect file paths
    """
    if file_list is None:
        file_list = []

    try:
        items = sorted(os.listdir(directory))
        for item in items:

            item_path = os.path.join(directory, item)
            if os.path.isdir(item_path):
                # Skip directories that are in the exclusion list or start with a period
                if item in excluded_dirs or item.startswith("."):
                    output_file.write(f"{indent}[DIR] {item} (skipped)\n")
                    continue
                output_file.write(f"{indent}[DIR] {item}\n")
                list_project_structure(item_path, indent + "  ", output_file, file_list)
            else:
                # Check file extension only for files, not directories
                if Path(item).suffix.lower() not in include_extensions:
                    continue
                output_file.write(f"{indent}- {item}\n")
                # Only add files from the target directory to avoid processing too many files
                if os.path.dirname(item_path) == directory:
                    file_list.append(item_path)
    except PermissionError:
        output_file.write(f"{indent}[Permission Denied]\n")
    except Exception as e:
        output_file.write(f"{indent}[Error: {str(e)}]\n")


def print_file_contents(
    file_list, output_file, max_file_size_kb=100, max_line_count=500
):
    """Writes the contents of selected files in the file list to the output file.

    Args:
        file_list (list): List of file paths to process
        output_file: File object to write output to
        max_file_size_kb (int): Maximum file size to process in KB
        max_line_count (int): Maximum number of lines to show per file
    """
    for file_path in file_list:
        try:
            # Skip files that are too large
            if os.path.getsize(file_path) > max_file_size_kb * 1024:
                output_file.write(
                    f"\n[Skipped {file_path}: File too large ({os.path.getsize(file_path) // 1024} KB)]\n"
                )
                continue

            # Skip files that don't have typical text extensions
            if Path(file_path).suffix.lower() not in text_extensions:
                # output_file.write(f"\n[Skipped {file_path}: Non-text file type]\n")
                continue

            # Skip binary files
            if is_binary_file(file_path):
                # output_file.write(f"\n[Skipped {file_path}: Binary file detected]\n")
                continue

            with open(file_path, "r", encoding="utf-8", errors="ignore") as file:
                output_file.write(f"\n{'='*40}\nContents of {file_path}:\n{'='*40}\n")

                lines = []
                for i, line in enumerate(file):
                    if i >= max_line_count:
                        output_file.write(
                            f"... (truncated, {max_line_count} lines shown of {i+1} total) ...\n"
                        )
                        break
                    lines.append(f"  {line.rstrip()}")

                output_file.write("\n".join(lines) + "\n")

        except Exception as e:
            output_file.write(f"\n[Error reading file {file_path}: {e}]\n")


def is_binary_file(file_path):
    """Check if file is likely binary rather than text.

    Args:
        file_path (str): Path to the file to check

    Returns:
        bool: True if the file appears to be binary
    """
    try:
        with open(file_path, "rb") as file:
            chunk = file.read(1024)
            return (
                b"\0" in chunk
            )  # Simple heuristic: binary files often contain null bytes
    except Exception:
        return True  # If we can't open it, assume binary to be safe


def main():
    """Main function to execute the script logic."""
    parser = argparse.ArgumentParser(description="Project Structure Scanner")
    parser.add_argument(
        "-d",
        "--directory",
        help="Directory to scan (default: script directory)",
        default="",
    )
    parser.add_argument(
        "-s",
        "--max-size",
        type=int,
        default=100,
        help="Maximum file size in KB (default: 100)",
    )
    parser.add_argument(
        "-l",
        "--max-lines",
        type=int,
        default=500,
        help="Maximum lines to show per file (default: 500)",
    )
    parser.add_argument(
        "--structure-only",
        action="store_true",
        help="Only show directory structure, skip file contents",
    )

    args = parser.parse_args()

    directory_to_scan = args.directory.strip()
    if not directory_to_scan:
        directory_to_scan = os.path.dirname(os.path.abspath(__file__))

    directory_path = Path(directory_to_scan)

    if not directory_path.exists() or not directory_path.is_dir():
        print("Invalid directory path!")
        return

    output_file_path = directory_path / "project_structure.txt"
    script_path = os.path.abspath(__file__)

    print(f"Scanning directory: {directory_path}")
    print(f"This might take some time depending on the project size...")

    with open(output_file_path, "w", encoding="utf-8") as output_file:
        output_file.write(f"PROJECT STRUCTURE FOR: {directory_path}\n")
        output_file.write(f"{'=' * 50}\n\n")

        file_list = []
        list_project_structure(
            str(directory_path), output_file=output_file, file_list=file_list
        )

        # Filter out the output file and this script from the file list
        file_list = [
            f for f in file_list if f != str(output_file_path) and f != script_path
        ]

        if not args.structure_only:
            print_file_contents(
                file_list,
                output_file,
                max_file_size_kb=args.max_size,
                max_line_count=args.max_lines,
            )
        else:
            output_file.write("\nFile contents skipped (structure-only mode)\n")

    print(f"Project structure saved to {output_file_path}")


if __name__ == "__main__":
    main()
