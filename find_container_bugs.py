import os
import re

def find_in_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    # Simple state machine to find Container calls
    # We look for Container( ... ) and check for color: AND decoration:
    
    stack = []
    in_container = False
    container_start = -1
    
    for i in range(len(content)):
        if content[i:i+10] == 'Container(':
            if not in_container:
                in_container = True
                container_start = i
                stack = ['(']
        elif in_container:
            if content[i] == '(':
                stack.append('(')
            elif content[i] == ')':
                stack.pop()
                if not stack:
                    # End of Container block
                    block = content[container_start:i+1]
                    # Check if color: and decoration: are both at the TOP level of this block
                    # (not inside another widget)
                    if has_conflict(block):
                        line_num = content[:container_start].count('\n') + 1
                        print(f"CONFLICT FOUND in {filepath} at line {line_num}")
                        print(block)
                        print("-" * 40)
                    in_container = False

def has_conflict(block):
    # Regex to find color: and decoration: parameters
    # We want to make sure they are NOT inside another nested call (like BoxDecoration)
    # This is a bit tricky with regex, but since color: is usually a direct arg 
    # and decoration: is usually a direct arg, we can check for them.
    # However, decoration: BoxDecoration(color: ...) is NOT a conflict.
    # A conflict is Container(color: ..., decoration: ...)
    
    # Let's count top-level arguments
    # We'll split by commas but respect nested parens
    args = []
    current_arg = ""
    nesting = 0
    # Start after Container(
    start_idx = block.find('(') + 1
    for char in block[start_idx:-1]:
        if char == '(' or char == '[' or char == '{':
            nesting += 1
            current_arg += char
        elif char == ')' or char == ']' or char == '}':
            nesting -= 1
            current_arg += char
        elif char == ',' and nesting == 0:
            args.append(current_arg.strip())
            current_arg = ""
        else:
            current_arg += char
    if current_arg:
        args.append(current_arg.strip())
    
    has_color = False
    has_decoration = False
    for arg in args:
        if arg.startswith('color:'):
            has_color = True
        if arg.startswith('decoration:'):
            has_decoration = True
            
    return has_color and has_decoration

def main():
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                find_in_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
