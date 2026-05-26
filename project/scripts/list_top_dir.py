import os
import sys

# Why would I include this if the directories are right here??
# Because some times just having a printed list is nice rather 
# than copying and pasting each directory name.
def main():
    target_dir = sys.argv[1] if len(sys.argv) > 1 else '.'
    
    print(f"\n--- TOP-LEVEL DIRECTORIES IN: {target_dir} ---")

    # Just grab the surface items
    for item in os.listdir(target_dir):
        # Skip hidden stuff like .git or .godot
        if item.startswith('.'):
            continue
        
        item_path = os.path.join(target_dir, item)
        
        # If it's a folder, smash it to uppercase and print it
        if os.path.isdir(item_path):
            print(item.upper())

    print("---------------------------------\n")
    input("Press Enter to close this window...")

if __name__ == "__main__":
    main()