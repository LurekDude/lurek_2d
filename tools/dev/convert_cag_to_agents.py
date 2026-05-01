import os
import re

def convert_prompts():
    prompt_dir = r'c:\Users\tombl\Documents\luna2d\.github\prompts'
    workflow_dir = r'c:\Users\tombl\Documents\luna2d\.agents\workflows'
    
    if not os.path.exists(workflow_dir):
        os.makedirs(workflow_dir)
        
    for filename in os.listdir(prompt_dir):
        if filename.endswith('.prompt.md'):
            with open(os.path.join(prompt_dir, filename), 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extract description from frontmatter
            desc_match = re.search(r'^description:\s*"(.*?)"', content, re.MULTILINE)
            if not desc_match:
                desc_match = re.search(r'^description:\s*(.*)', content, re.MULTILINE)
            
            description = desc_match.group(1).strip() if desc_match else ""
            
            # Extract body (everything after the second ---)
            body_match = re.match(r'^---\s*\n.*?\n---\s*\n(.*)', content, re.DOTALL)
            body = body_match.group(1) if body_match else content
            
            new_filename = filename.replace('.prompt.md', '.md')
            with open(os.path.join(workflow_dir, new_filename), 'w', encoding='utf-8') as f:
                f.write('---\n')
                f.write(f'description: {description}\n')
                f.write('---\n\n')
                f.write(body)
            print(f'Converted prompt: {filename} -> {new_filename}')

def convert_skills():
    skill_dir = r'c:\Users\tombl\Documents\luna2d\.github\skills'
    rule_dir = r'c:\Users\tombl\Documents\luna2d\.agents\rules'
    
    if not os.path.exists(rule_dir):
        os.makedirs(rule_dir)
        
    for skill_name in os.listdir(skill_dir):
        skill_path = os.path.join(skill_dir, skill_name)
        if os.path.isdir(skill_path):
            skill_file = os.path.join(skill_path, 'SKILL.md')
            if os.path.exists(skill_file):
                with open(skill_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Extract description from frontmatter
                desc_match = re.search(r'^description:\s*"(.*?)"', content, re.MULTILINE)
                if not desc_match:
                    desc_match = re.search(r'^description:\s*(.*)', content, re.MULTILINE)
                
                description = desc_match.group(1).strip() if desc_match else ""
                
                new_filename = f'{skill_name}.md'
                with open(os.path.join(rule_dir, new_filename), 'w', encoding='utf-8') as f:
                    f.write('---\n')
                    f.write('trigger: model_decision\n')
                    f.write(f'description: {description}\n')
                    f.write('---\n\n')
                    f.write(content)
                print(f'Converted skill: {skill_name} -> {new_filename}')

if __name__ == '__main__':
    convert_prompts()
    convert_skills()
