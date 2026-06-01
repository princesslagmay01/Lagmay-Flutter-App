import os
import re

def fix_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        new_content = content
        
        # 1. Replace .withOpacity(x) with .withValues(alpha: x)
        new_content = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', new_content)

        # 2. Fix print statements in sync_service.dart
        if 'sync_service.dart' in filepath:
            new_content = new_content.replace("print('", "debugPrint('")
            new_content = new_content.replace("print(", "debugPrint(")
            # Add debugPrint import if not there
            if 'debugPrint' in new_content and 'import \'package:flutter/foundation.dart\';' not in new_content:
                new_content = "import 'package:flutter/foundation.dart';\n" + new_content

        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Fixed {filepath}")
    except Exception as e:
        print(f"Error processing {filepath}: {e}")

directory = r'c:\flutter\lagmay\lib'

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))
