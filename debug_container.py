import os
import re

def find_container_errors(root_dir):
    pattern = re.compile(r'Container\s*\((.*?)\)', re.DOTALL)
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    for match in pattern.finditer(content):
                        body = match.group(1)
                        # Check if color: is at the top level of Container (not inside BoxDecoration)
                        # This is a bit tricky with regex, so we'll look for color: 
                        # and then see if it's inside a nested ( )
                        
                        # Simplified check: does 'color:' and 'decoration:' both exist in the Container body
                        # AND is 'color:' NOT inside 'BoxDecoration('?
                        # Actually, if 'color:' is a Direct argument to Container, and 'decoration:' is too, it fails.
                        
                        if 'color:' in body and 'decoration:' in body:
                            # Try to see if color: is followed by BoxDecoration or vice versa in a way that implies both are direct args
                            # A simple check: if 'color:' is NOT preceded by 'BoxDecoration(' but 'decoration:' exists.
                            # But 'color:' could be inside something else.
                            
                            # Let's just print all Containers that have both and we will manually check.
                            # The body is what's inside Container(...)
                            # We need to make sure both are direct arguments.
                            
                            # A direct argument is usually at the start of a line or after a comma, 
                            # and not deeper in nesting.
                            print(f"Potential conflict in {path}:")
                            print(match.group(0))
                            print("-" * 20)

if __name__ == "__main__":
    find_container_errors('lib')
