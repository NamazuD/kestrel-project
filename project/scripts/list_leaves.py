import os
import sys

def main():
    # Default to current directory if no argument is given
    target_dir = sys.argv[1] if len(sys.argv) > 1 else '.'
    
    if not os.path.isdir(target_dir):
        print(f"Error: '{target_dir}' is not a valid directory.", file=sys.stderr)
        # Keep the window open even on an error
        input("\nPress Enter to close...")
        sys.exit(1)

    print(f"\n--- DETECTED LEAF DIRECTORIES IN: {target_dir} ---")

    for root, dirs, files in os.walk(target_dir):
        # Skip hidden directories like .git or .godot
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        
        # If there are no sub-directories left, it's a leaf node
        if not dirs:
            leaf_name = os.path.basename(root)
            print(leaf_name)

    print("---------------------------------\n")
    
    # THE FIX: This blocks the window from closing automatically
    input("Press Enter to close this window...")

if __name__ == "__main__":
    main()