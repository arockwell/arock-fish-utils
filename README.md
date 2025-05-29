# 🐟 arock-fish-utils

Alex Rockwell's collection of Fish utilities

## 📦 Installation

### With Fisher
\`\`\`fish
fisher install your-username/arock-fish-utils
\`\`\`

### Manual Installation
\`\`\`fish
git clone https://github.com/your-username/arock-fish-utils.git
cd arock-fish-utils
fisher install .
\`\`\`

## 🛠️ Development

### Adding Functions
Create new functions in the \`functions/\` directory:

\`\`\`fish
# functions/my-function.fish
function my-function -d "Description of my function"
    # Your function code here
end
\`\`\`

### Adding Completions
Add tab completions in the \`completions/\` directory:

\`\`\`fish
# completions/my-function.fish
complete -c my-function -s h -l help -d "Show help"
\`\`\`

### Configuration
Add startup configuration in \`conf.d/arock-fish-utils.fish\`

## 🤝 Contributing

1. 🍴 Fork the repository
2. 🌟 Create a feature branch
3. 💾 Commit your changes
4. 📤 Push to the branch
5. 🎉 Create a Pull Request

## 📄 License

MIT License - see LICENSE file for details.
