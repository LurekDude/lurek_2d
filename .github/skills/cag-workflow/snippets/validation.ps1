# Validate all .github/ CAG files
python tools/validate/cag_validate.py

# Validate one family
python tools/validate/cag_validate.py --type skill
python tools/validate/cag_validate.py --type agent

# Validate a single file
python tools/validate/cag_validate.py --file .github/skills/my-skill/SKILL.md
